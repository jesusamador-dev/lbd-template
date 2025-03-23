from uuid import uuid4


class Project:
    def __init__(self, name: str, prefix: str, owner: str):
        self.id = str(uuid4())
        self.name = name
        self.prefix = prefix
        self.owner_id = owner
        self.resources = []

    def add_resource(self, resource):
        self.resources.append(resource)
