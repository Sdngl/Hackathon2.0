from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
def api_exception_handler(exc, context):
    response=exception_handler(exc,context)
    if response is None:
        return Response({'success':False,'data':None,'error':{'code':'INTERNAL_ERROR','message':'An unexpected error occurred.'}},status=500)
    code='REQUEST_ERROR'
    if response.status_code==401: code='AUTHENTICATION_REQUIRED'
    elif response.status_code==429: code='AI_RATE_LIMITED'
    detail=response.data.get('detail') if isinstance(response.data,dict) else None
    msg=str(detail or 'The request could not be processed.')
    return Response({'success':False,'data':None,'error':{'code':code,'message':msg}},status=response.status_code)
