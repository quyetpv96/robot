import os

class PathUtils:
    def get_parent_directory(self, path):
        return os.path.dirname(path)