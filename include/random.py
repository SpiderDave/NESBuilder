import random

def is_sequence(obj):
    try:
        len(obj)
        obj[0:0]
        return True
    except TypeError:
        return False

#def isFloat(n):
#    if isinstance(i, float):
#        return True
#    return False

class RNG(random.Random):
    # make class instance directly callable
#    def __call__(self, *args, **kwargs):
#        self.random(*args, **kwargs)
    def isFloat(n):
        if isinstance(i, float):
            return True
        return False
    def random(self, *args):
        if len(args) == 1:
            if is_sequence(args[0]):
                # choice(x)
                return super().choice(args[0])
            else:
                # randint(0, x)
                return super().randint(0, args[0])
        if len(args) == 0:
            # random()
            return super().random()
        elif len(args) == 2:
            # random(x, y)
            return super().randint(*args)
    def choice(self, *args):
        if len(args) > 1 or not is_sequence(args[0]):
            return super().choice(args)
        else:
            return super().choice(args[0])
