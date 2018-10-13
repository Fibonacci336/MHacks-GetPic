from rfc3986 import uri_reference
import hmac
import hashlib
import base64
from datetime import datetime
import sys

#1=Access Key ID, 2=SecretKey, 3=Associate Tag
accessKeyID = sys.argv[1]
secretKey = sys.argv[2]
associateTag = sys.argv[3]

exampleURL = "http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&AssociateTag=" + associateTag + "&Operation=ItemSearch&Keywords=the%20hunger%20games&SearchIndex=Books"

exampleURL += ("&AWSAccessKeyId=" + accessKeyID)

#Generate and Add Timestamp
utcTimestamp = datetime.utcnow().isoformat()
periodIndex = utcTimestamp.find('.')
utcTimestamp = utcTimestamp[:periodIndex]
utcTimestamp += "Z"

exampleURL += ("&Timestamp=" + utcTimestamp)

uriRef = uri_reference(exampleURL)

#Get Query String
urlQuery = uriRef.query

#Set Percent Encoding
encodedQuery = urlQuery.replace(',', '%2C')

encodedQuery = encodedQuery.replace(':', '%3A')

#Split List
splitList = encodedQuery.split('&')

#Sort by Byte Order
splitList.sort()

#Re-join
reorderedQuery = '&'.join(splitList)

#Prepare string for hashing

hashingString = "GET\nwebservices.amazon.com\n/onca/xml\n"+reorderedQuery

#Hash request for signature
digitalSig = hmac.new(secretKey, msg=hashingString, digestmod=hashlib.sha256).digest()
decodedSig = base64.b64encode(digitalSig).decode() 

#Percent Encoded +/= characters
decodedSig = decodedSig.replace('=', '%3D')

decodedSig = decodedSig.replace('+', '%2B')

#Add Sig to Query
finalQuery = urlQuery + "&Signature=" + decodedSig

finalURL = uriRef.scheme + "://" + uriRef.authority + uriRef.path + "?" + finalQuery

print(finalURL)
