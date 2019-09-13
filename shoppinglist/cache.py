from pyramid.static import QueryStringCacheBuster, ManifestCacheBuster


class ChecksumCacheBuster(QueryStringCacheBuster, ManifestCacheBuster):
    def __init__(self, manifest_spec, reload=False, param="hash"):
        QueryStringCacheBuster.__init__(self, param)
        ManifestCacheBuster.__init__(self, manifest_spec, reload)

    def parse_manifest(self, content):
        manifest = {}
        for line in content.decode().splitlines():
            checksum, filename = line.split(None, 1)
            filename = filename.lstrip("*")
            manifest[filename] = checksum
        return manifest

    def tokenize(self, request, subpath, kw):
        return self.manifest.get(subpath, '')
