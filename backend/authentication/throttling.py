from rest_framework.throttling import SimpleRateThrottle
class FirebaseUIDThrottle(SimpleRateThrottle):
    scope='ai'
    def get_cache_key(self,request,view):
        if request.path.endswith('/health/') or request.path.startswith('/api/schema') or request.path.startswith('/api/docs'): return None
        user=getattr(request,'user',None)
        ident=getattr(user,'uid',None) or self.get_ident(request)
        return self.cache_format % {'scope':self.scope,'ident':ident}
