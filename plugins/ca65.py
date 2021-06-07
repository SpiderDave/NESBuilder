from shlex import quote

class Tools:
    """
    Tools for invoking commands from the cc65 suite
    """

    _cc65path = ''

    def __init__(self, cc65path):
        """
        cc65path - base of cc65 distribution
        """
        self._cc65path = cc65path
    
    def forAssemble(self, *args, **kwargs):
        """
        runs ca65 with arguments
        """
        safe_args = [ quote(v) for v in args ]
        return [ quote(self._cc65path+'/bin/ca65.exe'), " ".join(safe_args) ]
    
    def forLink(self, *args,  **kwargs):
        """
        Well excuuuuuuse me...
        """
        safe_args = [ quote(v) for v in args ]
        return [ quote(self._cc65path+'/bin/ld65.exe'), " ".join(safe_args) ]

def cc65tools(cc65path):
    """
    Factory for Tools class
    """
    return Tools(cc65path)
    