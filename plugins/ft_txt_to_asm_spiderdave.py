# Original ft_txt_to_asm.py available at:
#   https://github.com/gradualgames/ggsound
#
# Changes by SpiderDave
#
#   * changed "is -1" to "== -1" to remove a warning.
#   * added default volume envelope when not set
#   * added a "return" when an error occurs
#   * changed silent instrument base name from "silent" to "_silent"
#   * added symbols: song_count, sfx_count
#   * adds title, author, copyright, comment to .asm file as comments.
#   * added handling for attempting to use a non-existing instrument
#   * accepts unquoted file parameter
#   * added handling for an empty stream
#   * partial handling of effect 'S' (Mute delay).  Works along row
#     boundries, not frames.
#   * single script defaults to asm6.  copy and change the value of
#     assembler below to use with ca65 or nesasm
#   * added handling for note release ("===").  Replaced with a note cut.
#   * sys.argv is now handled outside of main() and main has a paramter
#     to specify input_file.
#   * put everything in a class
#   * removed all use of "global"
#
# Todo:

import os
import sys
import math


class FT():
    assembler = None

    ARPEGGIOS_ENABLED = None
    silent_volume_index = None
    default_volume_index = None
    default_arpeggio_index = None
    flat_pitch_index = None
    default_duty_index = None
    silent_instrument_index = None
    instrument_id_to_index = None
    macros = None
    macro_id_to_index = None
    instruments = None
    song_tracks = None
    sfx_tracks = None
    title = None
    comment = None
    author = None
    copyright = None
    
    lo_byte_operator = None
    hi_byte_operator = None
    define_byte_directive = None
    define_word_directive = None
    
    LINE_WIDTH = None
    
    dpcm_samples = None
    dpcm_sample_id_to_index = None
    key_dpcms = None
    macro_type_to_str = None
    arpeggio_sub_type_to_str = None
    default_volume = None
    
    def __init__(self):
        # do the usual init
        super().__init__()
        
        # specify asm6, ca65, or nesasm
        self.assembler = "asm6"

        self.ARPEGGIOS_ENABLED = True
        self.silent_volume_index = None
        self.default_volume_index = None
        self.default_arpeggio_index = None
        self.flat_pitch_index = None
        self.default_duty_index = None
        self.silent_instrument_index = None
        self.instrument_id_to_index = {-1: -1}
        self.macros = {"volume": [],
                  "arpeggio": [],
                  "pitch": [],
                  "duty": []}
        self.macro_id_to_index = {"volume": {-1: -1},
                             "arpeggio": {-1: -1},
                             "pitch": {-1: -1},
                             "duty": {-1: -1}}
        self.instruments = []
        self.song_tracks = []
        self.sfx_tracks = []
        self.title = None
        self.comment = []
        self.author = None
        self.copyright = None
        
        if self.assembler == 'asm6':
            self.lo_byte_operator = "<"
            self.hi_byte_operator = ">"
            self.define_byte_directive = "  .db "
            self.define_word_directive = "  .dw "
        elif self.assembler == 'ca65':
            self.lo_byte_operator = "<"
            self.hi_byte_operator = ">"
            self.define_byte_directive = "  .byte "
            self.define_word_directive = "  .word "
        elif self.assembler == 'nesasm':
            self.lo_byte_operator = "low"
            self.hi_byte_operator = "high"
            self.define_byte_directive = "  .db "
            self.define_word_directive = "  .dw "

        self.LINE_WIDTH = 64
        
        self.dpcm_samples = []
        self.dpcm_sample_id_to_index = {-1: -1}
        self.key_dpcms = {}
        self.macro_type_to_str = {0: "volume",
                             1: "arpeggio",
                             2: "pitch",
                             4: "duty"}
        self.arpeggio_sub_type_to_str = {0: "ARP_TYPE_ABSOLUTE",
                                    1: "ARP_TYPE_FIXED",
                                    2: "ARP_TYPE_RELATIVE"}
        self.default_volume = 15             # This is for when volume envelope isn't set

    #Splits a note string, formats the note and converts the instrument index to an integer
    def process_note(self, note):
        split_note = note.split()
        split_note[0] = self.format_note(split_note[0])
        instrument_index = -1
        if split_note[1] != "..":
            instrument_index = int(split_note[1], base=16)
        split_note[1] = instrument_index
        return split_note

    #Formats a note to match equates in our soundengine.
    def format_note(self, note):
        if note != "...":
            #if third char is #, this is a noise note (which don't use the note equates,
            #they are just raw values.) Note: previously this code mirrored the value
            #against 15, but this has been delegated to apu register upload within
            #ggsound itself to allow noise pitch envelopes to operate naturally.
            if note[2] == "#":
                note = str(int(note[0], 16))
            else:
                if note[1] == "#":
                    note = note[0] + "S" + note[2]
                if note[1] == "-":
                    note = note[0] + note[2]
            return note
        else:
            return None


    #Returns (note length in rows, whether this is last note, jump frame)
    #Can then be multiplied by track speed to get STL frame count value.
    def get_note_info(self, song_rows, channel, index):

        #starting at a note of a valid index the length is always at least 1
        note_length = 1
        i = index + 1
        if i == len(song_rows):
            return (note_length, True, None)
        #count the length of the note by the number of rows that do not have a note in them or the end of the song
        while i < len(song_rows) and (song_rows[i][channel][0] is None or song_rows[i][channel][3][0] == "B"):
            if song_rows[i][channel][3][0] == "B":
                jump_frame = int(song_rows[i][channel][3][1:], 16)
                return (note_length + 1, True, jump_frame)
            i += 1
            note_length += 1

        return (note_length, False, None)


    #Generates a stream in asm format for a particular channel of a track.
    #Stops short of fully formatting the stream for output to a file. Instead,
    #it generates asm code for each note individually ignoring whether to start
    #or end a line, or output a .byte directive, or add commas, etc. That will be
    #done in a separate step.
    #Returns (stream, whether the stream is silent, jump frame)
    def generate_stream(self, track, order, channel, speed):
        i = 0
        jump_frame = 0
        current_instrument = None
        current_note_length = None
        stream_is_silent = True
        stream = []
        if len(track["patterns"]) == 0:
            return (stream, stream_is_silent, jump_frame)
        if order not in track["patterns"]:
            return (stream, stream_is_silent, jump_frame)
        track_rows = track["patterns"][order]
        
        # Preprocess track rows to handle effect 'S' (Mute delay)
        # It can only handle muting on row boundries, not frames
        # Works by inserting a not cut if needed
        for rowNum, track_row in enumerate(track_rows):
            trackRowChannel = track_row[channel]
            note = trackRowChannel[0]
            if note and trackRowChannel[3][0] == 'S':
                n = int(trackRowChannel[3][1:], 16)
                n = math.floor(n / track["speed"])
                if n == 0:
                    track["patterns"][order][rowNum][channel][0:1] = [None, -1]
                else:
                    for ii in range(1, n+1):
                        if track_rows[rowNum+ii][channel][0] is None:
                            if (ii == n) or (track_rows[rowNum+ii+1][channel][0] is not None):
                                track["patterns"][order][rowNum+ii][channel][0:2] = ['--', -1]
                                break
                        else:
                            break

        while True:
            note = track_rows[i][channel][0]
            instrument = -1
            #Do not consider instrument column for note cuts.
            if note in('--', '=='):
                # --- is a note cut
                # === is a note release
                
                #let the following logic output a silent A0.
                note = None
            else:
                instrument = self.instrument_id_to_index.get(track_rows[i][channel][1], None)

            note_info = self.get_note_info(track_rows, channel, i)
            note_length = note_info[0]
            last_note = note_info[1]
            jump_frame = note_info[2]
            
            if track["name"].startswith("_sfx_") and note_length == len(track_rows) and instrument == -1:
                #In this case, we don't want to generate any stream data. This stream is completely empty.
                break

            note_output = []
            #If the note is none, change the note settings to use a silent volume envelope (which we output while generating
            #final asm file), and no pitch or duty envelope, and an arbitrary note. We use A0.
            if note is None:
                note = "A0"
                instrument = self.silent_instrument_index

            if instrument != current_instrument:
                note_output.append("STI,%s" % (instrument))
                current_instrument = instrument

            if current_instrument != self.silent_instrument_index:
                stream_is_silent = False

            if note_length != current_note_length:
                #we support notes longer than 255 by using SLH as well as SLL
                real_note_length = note_length * speed
                if real_note_length > 255:
                    note_output.append("SLL,%s" % (real_note_length & 0x00ff))
                    note_output.append("SLH,%s" % ((real_note_length & 0xff00) >> 8))
                    #always force note length to be output after a long note since we will
                    #have to reset the note length again. This covers the case of more than
                    #one ultra long note after another.
                    current_note_length = 0
                elif not track["name"].startswith("_sfx_") and real_note_length >= 1 and real_note_length <= 16:
                    #output special note length opcodes for songs, but not for sound effects
                    note_output.append("SL%s" % (format(real_note_length, "X")[-1]))
                    current_note_length = note_length
                else:
                    note_output.append("SLL,%s" % (real_note_length))
                    current_note_length = note_length

            note_output.append(note)

            stream.append(note_output)

            if last_note:
                break
            i += note_length
            if i == len(track_rows):
                break

        return (stream, stream_is_silent, jump_frame)


    #This function converts the passed in stream to a sound effect. All this means is,
    #it searches for a long, silent notes at the end and trims it. Finally, it checks the
    #envelope settings prior to the last note, finds the one with the greatest length, and
    #sets the last note length to this value. Then the stream can be used as a sound effect.
    def convert_stream_to_sfx(self, stream):
        #first search for last silent note and delete it and everything after it
        if len(stream) == 0:
            return
        silent_note_index = -1
        for i in range(len(stream) - 1, 0, -1):
            for j in range(0, len(stream[i])):
                if stream[i][j] == "STI,%s" % self.silent_instrument_index:
                    silent_note_index = i
                    break
        if silent_note_index != -1:
            del stream[silent_note_index: len(stream)]

        #delete any SLL or SLH opcodes
        last_note = stream[len(stream) - 1]
        sll_slh_opcodes = []
        for opcode in last_note:
            if "SLL" in opcode or "SLH" in opcode:
                sll_slh_opcodes.append(opcode)
        for opcode in sll_slh_opcodes:
            last_note.remove(opcode)

        #determine which envelope indices are applied to the last note
        last_note_volume_index = None
        last_note_arpeggio_index = None
        last_note_pitch_index = None
        last_note_duty_index = None
        last_instrument_index = None
        for i in range(len(stream) - 1, -1, -1):
            note = stream[i]
            for opcode in note:
                split_opcode = opcode.split(",")
                if len(split_opcode) == 2:
                    instrument_opcode = split_opcode[0]
                    instrument_index = int(split_opcode[1])
                    if last_instrument_index == None and instrument_opcode == "STI":
                        last_note_volume_index = self.instruments[instrument_index]["volume"]
                        last_note_pitch_index = self.instruments[instrument_index]["pitch"]
                        last_note_duty_index = self.instruments[instrument_index]["duty"]
                        last_note_arpeggio_index = self.instruments[instrument_index]["arpeggio"]

        #find max envelope length on last note
        max_envelope_length = 0
        for envelope_type, envelope_index in zip(["volume", "arpeggio", "pitch", "duty"], [last_note_volume_index, last_note_arpeggio_index, last_note_pitch_index, last_note_duty_index]):
            if envelope_index is not None:
                envelope_length = len(self.macros[envelope_type][envelope_index]["values"])
                if envelope_length > max_envelope_length:
                    max_envelope_length = envelope_length

        #add a set length opcode to the last note matching this max envelope length so the whole sfx will be heard
        last_note.insert(0, "SLL,%s" % max_envelope_length)


    def generate_asm_from_stream(self, stream):
        asm = []
        current_line = ""
        for i in range(0, len(stream)):
            for note in stream[i]:
                if len(current_line) == 0:
                    current_line += "%s%s" % (self.define_byte_directive, note)
                else:
                    current_line += "," + note
                if len(current_line) > self.LINE_WIDTH - len("," + note):
                    current_line += '\n'
                    asm.append(current_line)
                    current_line = ""
        if len(current_line):
            current_line += '\n'
        asm.append(current_line)

        return asm


    def generate_asm_from_bytes(self, bytes, bytes_per_line, start_line=False, byte_prefix="$"):
        if not start_line:
            start_line = self.define_byte_directive
        
        asm = ""
        current_line = start_line
        bytes_on_line = 0
        for byte in bytes:
            if byte < 0:
                byte = 256 + byte
            if current_line == start_line:
                current_line += byte_prefix + format(byte, '02x')
                bytes_on_line += 1
            else:
                current_line += "," + byte_prefix + format(byte, '02x')
                bytes_on_line += 1
            if bytes_on_line >= bytes_per_line:
                asm += current_line + '\n'
                current_line = start_line
                bytes_on_line = 0
        if bytes_on_line > 0:
            asm += current_line + '\n'

        return asm


    def sanitize_label(self, label):
        new_label = "_"
        allowed_characters = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        for c in label:
            if c not in allowed_characters:
                new_label = new_label + "%x" % ord(c)
            else:
                new_label = new_label + c
        return new_label


    def main(self, input_file = False):
        if not input_file:
            print("%s expects one argument: input_file" % (sys.argv[0]))
            return

        file_name_without_ext = os.path.splitext(input_file)[0]
        output_file = file_name_without_ext + ".asm"
        dpcm_output_file = file_name_without_ext + "_dpcm.asm"

        lines = []
        with open(input_file) as f:
            lines = f.readlines()

        #Look for MACRO, INST2A03, TRACK, COLUMNS, ORDER, PATTERN, ROW, DPCMDEF, DPCM, KEYDPCM
        current_pattern = None
        current_track = None
        current_dpcm_sample = None
        track_index = 1
        for line in lines:
            split_line = line.split()
            if len(split_line) >= 1:
                if split_line[0] == "COMMENT":
                    commentText = line.split('"',1)[1].rsplit('"',1)[0].replace('""', '"')
                    self.comment.append(commentText)
                if split_line[0] == "TITLE":
                    self.title = line.split('"',1)[1].rsplit('"',1)[0].replace('""', '"')
                if split_line[0] == "AUTHOR":
                    self.author = line.split('"',1)[1].rsplit('"',1)[0].replace('""', '"')
                if split_line[0] == "COPYRIGHT":
                    self.copyright = line.split('"',1)[1].rsplit('"',1)[0].replace('""', '"')
                if split_line[0] == "MACRO":
                    macro_split_line = line.split(":")
                    type_index = macro_split_line[0].split()
                    values = macro_split_line[1].split()
                    macro = {}
                    macro["type"] = int(type_index[1])
                    macro["loop_point"] = int(type_index[3])
                    macro["sub_type"] = int(type_index[5])
                    macro["values"] = [int(value) for value in values]
                    self.macros[self.macro_type_to_str[macro["type"]]].append(macro)

                    macro["id"] = int(type_index[2])
                    macro["index"] = self.macros[self.macro_type_to_str[macro["type"]]].index(macro)
                    self.macro_id_to_index[self.macro_type_to_str[macro["type"]]][macro["id"]] = macro["index"]

                if split_line[0] == "INST2A03":
                    inst_split_line = line.split()
                    instrument = {}
                    instrument["volume"] = self.macro_id_to_index["volume"][int(inst_split_line[2])]
                    instrument["arpeggio"] = self.macro_id_to_index["arpeggio"][int(inst_split_line[3])]
                    instrument["pitch"] = self.macro_id_to_index["pitch"][int(inst_split_line[4])]
                    instrument["duty"] = self.macro_id_to_index["duty"][int(inst_split_line[6])]
                    self.instruments.append(instrument)

                    instrument["id"] = int(inst_split_line[1])
                    instrument["index"] = self.instruments.index(instrument)
                    instrument["name"] = self.sanitize_label("%s_%s" % ("_".join(inst_split_line[7:]).replace("\"", ""), instrument["index"]))
                    self.instrument_id_to_index[instrument["id"]] = instrument["index"]

                if split_line[0] == "TRACK":
                    current_track = {}
                    current_track["orders"] = []
                    current_track["patterns"] = {}

                    track_separate_params_name = line.split("\"")
                    track_split_line = track_separate_params_name[0].split()

                    current_track["pattern_length"] = int(track_split_line[1])
                    current_track["speed"] = int(track_split_line[2])
                    current_track["tempo"] = int(track_split_line[3])
                    current_track["name"] = self.sanitize_label(track_separate_params_name[1])
                    current_track["displayName"] = track_separate_params_name[1]
                    if current_track["name"].startswith("_sfx_"):
                        current_track['index'] = track_index
                        track_index += 1
                        self.sfx_tracks.append(current_track)
                    else:
                        current_track['index'] = track_index
                        track_index += 1
                        self.song_tracks.append(current_track)

                if split_line[0] == "ORDER":
                    order_split_line = line.split(":")
                    order_values = [int(value, 16) for value in order_split_line[1].split()]
                    order = {}
                    order["square1"] = order_values[0]
                    order["square2"] = order_values[1]
                    order["triangle"] = order_values[2]
                    order["noise"] = order_values[3]
                    order["dpcm"] = order_values[4]
                    current_track["orders"].append(order)

                if split_line[0] == "PATTERN":
                    pattern_split_line = line.split(" ")
                    pattern_number = int(pattern_split_line[1], 16)
                    current_pattern = []
                    current_track["patterns"][pattern_number] = current_pattern

                #relies on there being a pattern to insert rows into.
                if split_line[0] == "ROW":
                    if current_pattern != None:
                        row_split_line = line.split(":")
                        row_header = row_split_line[0].split()

                        #Format the notes to match our soundengine equates
                        square1 = self.process_note(row_split_line[1])
                        square2 = self.process_note(row_split_line[2])
                        triangle = self.process_note(row_split_line[3])
                        noise = self.process_note(row_split_line[4])
                        dpcm = self.process_note(row_split_line[5])

                        row = {}
                        row["index"] = int(row_header[1], 16)
                        row["square1"] = square1
                        row["square2"] = square2
                        row["triangle"] = triangle
                        row["noise"] = noise
                        row["dpcm"] = dpcm
                        current_pattern.append(row)

                if split_line[0] == "DPCMDEF":
                    current_dpcm_sample = {}

                    split_params_name = line.split("\"")
                    split_line = split_params_name[0].split()

                    current_dpcm_sample["length"] = int(split_line[2])
                    current_dpcm_sample["name"] = "dpcm_sample" + self.sanitize_label(split_params_name[1])
                    current_dpcm_sample["data"] = []

                    self.dpcm_samples.append(current_dpcm_sample)

                    current_dpcm_sample["id"] = int(split_line[1])
                    current_dpcm_sample["index"] = self.dpcm_samples.index(current_dpcm_sample)
                    self.dpcm_sample_id_to_index[current_dpcm_sample["id"]] = current_dpcm_sample["index"]

                if split_line[0] == "DPCM":
                    if current_dpcm_sample != None:
                        split_line = line.split(":")
                        values = split_line[1].split()
                        for value in values:
                            current_dpcm_sample["data"].append(int(value, 16))

                if split_line[0] == "KEYDPCM":
                    split_line = line.split()
                    key_dpcm = {}
                    key_dpcm["octave"] = int(split_line[2])
                    key_dpcm["semitone"] = int(split_line[3])
                    key_dpcm["sample_index"] = int(split_line[4])
                    key_dpcm["pitch_index"] = int(split_line[5])
                    key_dpcm["loop"] = int(split_line[6])
                    note = (key_dpcm["octave"] * 12 + key_dpcm["semitone"])
                    self.key_dpcms[note] = key_dpcm

        #At this point, we've gathered all of the exported song data and we're ready
        #to convert it to asm directives.

        #add default silent volume macro for silent notes.
        macro = {}
        macro["type"] = 0
        self.silent_volume_index = len(self.macros["volume"])
        macro["index"] = self.silent_volume_index
        macro["values"] = [0]
        macro["loop_point"] = -1
        macro["sub_type"] = 0
        self.macros["volume"].append(macro)

        #add default volume macro.
        macro = {}
        macro["type"] = 0
        self.default_volume_index = len(self.macros["volume"])
        macro["index"] = self.default_volume_index
        macro["values"] = [self.default_volume]
        macro["loop_point"] = -1
        macro["sub_type"] = 0
        self.macros["volume"].append(macro)

        #add default arpeggio macro.
        macro = {}
        macro["type"] = 1
        self.default_arpeggio_index = len(self.macros["arpeggio"])
        macro["index"] = self.default_arpeggio_index
        macro["values"] = []
        macro["loop_point"] = -1
        macro["sub_type"] = 0
        self.macros["arpeggio"].append(macro)

        #add default flat pitch envelope for instruments that don't specify a pitch envelope
        macro = {}
        macro["type"] = 2
        self.flat_pitch_index = len(self.macros["pitch"])
        macro["index"] = self.flat_pitch_index
        macro["values"] = [0]
        macro["loop_point"] = -1
        macro["sub_type"] = 0
        self.macros["pitch"].append(macro)

        #add a standard duty envelope for instruments that don't specify a duty envelope
        macro = {}
        macro["type"] = 4
        self.default_duty_index = len(self.macros["duty"])
        macro["index"] = self.default_duty_index
        macro["values"] = [0]
        macro["loop_point"] = -1
        macro["sub_type"] = 0
        self.macros["duty"].append(macro)

        #add a silent instrument
        instrument = {}
        self.silent_instrument_index = len(self.instruments)
        instrument["name"] = "_silent_%s" % self.silent_instrument_index
        instrument["volume"] = self.silent_volume_index
        instrument["arpeggio"] = self.default_arpeggio_index
        instrument["pitch"] = self.flat_pitch_index
        instrument["duty"] = self.default_duty_index
        self.instruments.append(instrument)

        #generate dpcm sample file, if we have any dpcm samples
        #we assume the user will place this data at a 64 byte aligned location. All
        #the samples after that are guaranteed to be aligned to 64 byte positions
        #from this exporter.
        if len(self.dpcm_samples):
            with open(dpcm_output_file, 'w') as g:
                dpcm_relative_offset = 0
                for dpcm_sample in self.dpcm_samples:
                    g.write("%s:\n" % dpcm_sample["name"])
                    g.write(self.generate_asm_from_bytes(dpcm_sample["data"], 24))

                    address_of_next_sample = dpcm_relative_offset + len(dpcm_sample["data"])
                    bytes_until_aligned_address = 64 - (address_of_next_sample % 64)

                    if bytes_until_aligned_address != 0:
                        g.write(self.generate_asm_from_bytes([0] * bytes_until_aligned_address, 24))
                        dpcm_relative_offset += len(dpcm_sample["data"]) + bytes_until_aligned_address

                    g.write("\n")

        #generate the asm file.
        with open(output_file, 'w') as f:
            if self.title:
                f.write('; Title:     {}\n'.format(self.title))
            if self.author:
                f.write('; Author:    {}\n'.format(self.author))
            if self.copyright:
                f.write('; Copyright: {}\n'.format(self.copyright))
            if self.title or self.author or self.copyright:
                f.write('\n')
            
            if len(self.comment) > 0 and (''.join(self.comment)).strip() !='':
                f.write('\n; ---- Comment ----\n')
                for line in self.comment:
                    f.write('; {}\n'.format(line))
                f.write('; -----------------\n\n')

            f.write("song_count = %s\n" % len(self.song_tracks))
            f.write("sfx_count = %s\n" % len(self.sfx_tracks))
            f.write("\n")

            if len(self.song_tracks) > 0:
                #song enum
                for i in range(0, len(self.song_tracks)):
                    f.write("song_index%s = %s\n" % (self.song_tracks[i]["name"], i))
                f.write("\n")

            if len(self.sfx_tracks) > 0:
                #sfx enum
                for i in range(0, len(self.sfx_tracks)):
                    f.write("sfx_index%s = %s\n" % (self.sfx_tracks[i]["name"], i))
                f.write("\n")

            if len(self.song_tracks) > 0:
                #song list
                f.write("song_list:\n")
                for track in self.song_tracks:
                    f.write("%s%s\n" % (self.define_word_directive, track["name"]))
                f.write("\n")

            if len(self.sfx_tracks) > 0:
                #sfx list
                f.write("sfx_list:\n")
                for track in self.sfx_tracks:
                    f.write("%s%s\n" % (self.define_word_directive, track["name"]))
                f.write("\n")

            if len(self.instruments) > 0:
                #instrument list
                f.write("instrument_list:\n")
                for instrument in self.instruments:
                    f.write("%s%s\n" % (self.define_word_directive, instrument["name"]))
                f.write("\n")

            #dpcm lut lut
            if len(self.dpcm_samples):
                f.write("dpcm_list:\n")
                f.write("%sdpcm_samples_list\n" % self.define_word_directive)
                f.write("%sdpcm_note_to_sample_index\n" % self.define_word_directive)
                f.write("%sdpcm_note_to_sample_length\n" % self.define_word_directive)
                f.write("%sdpcm_note_to_loop_pitch_index\n" % self.define_word_directive)
                f.write("\n")

            #instruments
            for instrument in self.instruments:
                instrument_name = instrument["name"]
                
                volume_macro = self.macros["volume"][instrument["volume"]]
                pitch_macro = self.macros["pitch"][instrument["pitch"]]
                duty_macro = self.macros["duty"][instrument["duty"]]
                arpeggio_macro = self.macros["arpeggio"][instrument["arpeggio"]]
                
                # use default volume envelope if not specified
                if volume_macro['index'] == -1:
                    volume_macro = self.macros["volume"][self.default_volume_index]

                total_bytes = 3
                if self.ARPEGGIOS_ENABLED:
                    total_bytes = 5
                instrument_asm = []
                instrument_offsets = []

                instrument_macros = [volume_macro, pitch_macro, duty_macro]
                if self.ARPEGGIOS_ENABLED:
                    instrument_macros.append(arpeggio_macro)
                prefixes = ["", "", "DUTY_", ""]
                value_lambdas = [lambda v: v, lambda v: v, lambda v: v << 6, lambda v: v]

                for i in range(0, len(instrument_macros)):
                    macro = instrument_macros[i]
                    macro_length = 0
                    prefix = prefixes[i]
                    value_lambda = value_lambdas[i]
                    instrument_asm.append(self.define_byte_directive)
                    instrument_offsets.append(total_bytes)
                    for value in macro["values"]:
                        instrument_asm.append("%s," % value_lambda(value))
                        macro_length += 1
                    if macro["loop_point"] == -1:
                        instrument_asm.append("%sENV_STOP\n" % prefix)
                        macro_length += 1
                    else:
                        instrument_asm.append("%sENV_LOOP,%s\n" % (prefix, macro["loop_point"] + total_bytes))
                        macro_length += 2
                    total_bytes += macro_length

                f.write("%s:\n" % instrument_name)
                f.write(self.define_byte_directive)
                f.write("%s," % instrument_offsets[0])
                f.write("%s," % instrument_offsets[1])
                f.write("%s" % instrument_offsets[2])
                if self.ARPEGGIOS_ENABLED:
                    f.write(",%s," % instrument_offsets[3])
                    f.write("%s" % self.arpeggio_sub_type_to_str[arpeggio_macro["sub_type"]])
                f.write("\n")
                if total_bytes <= 256:
                    for byte in instrument_asm:
                        f.write(byte)
                else:
                    print("ERROR: Instrument %s could not fit into 256 bytes. To work around this, create two instruments with shorter envelopes where one instrument continues into the next.")
                    return

                f.write("\n")

            if len(self.dpcm_samples):
                #dpcm sample lut
                f.write("dpcm_samples_list:\n")
                for dpcm_sample in self.dpcm_samples:
                    f.write("%s%s(%s >> 6)\n" % (self.define_byte_directive, self.lo_byte_operator, dpcm_sample["name"]))
                f.write("\n")

                #dpcm key tables
                dpcm_note_to_sample_indices = []
                dpcm_note_to_sample_lengths = []
                dpcm_note_to_loop_pitch_indices = []
                for note in range(0, 95):
                    dpcm_note_to_sample_index = -1
                    dpcm_note_to_sample_length = -1
                    dpcm_note_to_loop_pitch_index = -1
                    if note in self.key_dpcms:
                        key_dpcm = self.key_dpcms[note]
                        if key_dpcm["sample_index"] in self.dpcm_sample_id_to_index:
                            dpcm_note_to_sample_index = self.dpcm_sample_id_to_index[key_dpcm["sample_index"]]
                            dpcm_note_to_sample_length = self.dpcm_samples[dpcm_note_to_sample_index]["length"] >> 4
                        else:
                            print("ERROR: Sample assignment for octave %s, semitone %s refers to unloaded sample %s" % (key_dpcm["octave"], key_dpcm["semitone"], key_dpcm["sample_index"]))
                            return
                        dpcm_note_to_loop_pitch_index = self.key_dpcms[note]["pitch_index"] | self.key_dpcms[note]["loop"] << 4

                    dpcm_note_to_sample_indices.append(dpcm_note_to_sample_index)
                    dpcm_note_to_sample_lengths.append(dpcm_note_to_sample_length)
                    dpcm_note_to_loop_pitch_indices.append(dpcm_note_to_loop_pitch_index)

                f.write("dpcm_note_to_sample_index:\n")
                f.write(self.generate_asm_from_bytes(dpcm_note_to_sample_indices, 24))
                f.write("\n")

                f.write("dpcm_note_to_sample_length:\n")
                f.write(self.generate_asm_from_bytes(dpcm_note_to_sample_lengths, 24))
                f.write("\n")

                f.write("dpcm_note_to_loop_pitch_index:\n")
                f.write(self.generate_asm_from_bytes(dpcm_note_to_loop_pitch_indices, 24))
                f.write("\n")

            all_tracks = self.song_tracks[:]
            all_tracks.extend(self.sfx_tracks)

            #all tracks
            for track in all_tracks:
                is_sfx = False
                if track["name"].startswith("_sfx_"):
                    is_sfx = True
                #header

                header = []
                header.append("%s:\n" % track["name"])
                if is_sfx:
                    header.append("%s0, 1\n" % self.define_byte_directive)
                    header.append("%s0, 1\n" % self.define_byte_directive)
                else:
                    ntsc_tempo = int((256.0 * (60.0/track["tempo"] * 15.0 * track["speed"])) / 6.0)
                    header.append("%s%s\n" % (self.define_byte_directive, ntsc_tempo & 0x00ff))
                    header.append("%s%s\n" % (self.define_byte_directive, (ntsc_tempo & 0xff00) >> 8))
                    pal_tempo = int((256.0 * (50.0/track["tempo"] * 15.0 * track["speed"])) / 6.0)
                    header.append("%s%s\n" % (self.define_byte_directive, pal_tempo & 0x00ff))
                    header.append("%s%s\n" % (self.define_byte_directive, (pal_tempo & 0xff00) >> 8))

                master_stream = []
                streams = []

                for channel in ["square1", "square2", "triangle", "noise", "dpcm"]:

                    unique_orders = set()
                    for order in track["orders"]:
                        unique_orders.add(order[channel])

                    channel_streams = []
                    entire_channel_silent = True
                    jump_frame = None
                    for order in unique_orders:
                        stream = None
                        if is_sfx == True:
                            stream_info = self.generate_stream(track, order, channel, track["speed"])
                            stream = stream_info[0]
                            if stream_info[1] == False:
                                entire_channel_silent = False
                            self.convert_stream_to_sfx(stream)
                            if stream_info[2] != None:
                                jump_frame = stream_info[2]
                        else:
                            stream_info = self.generate_stream(track, order, channel, 1)
                            stream = stream_info[0]
                            if not stream:
                                # load in something for an empty stream to prevent error
                                stream = [['STI', str(self.silent_instrument_index), 'SLL,{}'.format(track['pattern_length']), 'A0']]
                            if stream_info[1] == False:
                                entire_channel_silent = False
                            if stream_info[2] != None:
                                jump_frame = stream_info[2]

                        if len(stream) > 0:
                            asm = ''.join(self.generate_asm_from_stream(stream))
                            stream_label = "%s_%s_%s" % (track["name"], channel, order)
                            channel_streams.append("%s:\n" % stream_label)
                            channel_streams.extend(asm)
                            channel_streams.append("%sRET\n\n" % self.define_byte_directive)
                    if jump_frame == None:
                        jump_frame = 0

                    sub_stream_calls = []
                    if not entire_channel_silent:
                        for order in track["orders"]:
                            stream_label = "%s_%s_%s" % (track["name"], channel, order[channel])
                            sub_stream_calls.append("%sCAL,%s(%s),%s(%s)\n" % (self.define_byte_directive, self.lo_byte_operator, stream_label, self.hi_byte_operator, stream_label))
                        streams.extend(channel_streams)

                    if len(sub_stream_calls) > 0:
                        header.append("%s%s_%s\n" % (self.define_word_directive, track["name"], channel))
                        master_stream_header = "%s_%s" % (track["name"], channel)
                        master_stream.append("%s:\n" % master_stream_header)
                        loop_index = len(master_stream)
                        master_stream.extend(sub_stream_calls)
                        if is_sfx == True:
                            end_stream_opcode = "%sTRM\n" % self.define_byte_directive
                            master_stream.append(end_stream_opcode)
                        else:
                            master_stream_loop = "%s_loop" % master_stream_header
                            end_stream_opcode = "%sGOT\n%s%s\n\n" % (self.define_byte_directive, self.define_word_directive, master_stream_loop)
                            master_stream.insert(loop_index + jump_frame, "%s:\n" % master_stream_loop)
                            master_stream.append(end_stream_opcode)
                    else:
                        header.append("%s0\n" % self.define_word_directive)
                f.writelines(header)
                f.write("\n")
                f.writelines(master_stream)
                f.writelines(streams)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("%s expects one argument: input_file" % (sys.argv[0]))
    else:
       input_file = ' '.join(sys.argv[1:])
       ft = FT()
       ft.main(input_file)
