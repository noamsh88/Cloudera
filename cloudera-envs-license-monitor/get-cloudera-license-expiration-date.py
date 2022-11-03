import sys
import cm_client
from cm_client.rest import ApiException
from pprint import pprint
from dateutil.relativedelta import relativedelta
import datetime

#Get Cloudera host name
cdh_host = sys.argv[1]
#Get Cloudera API Version, e.g. v30 or v41
api_version = sys.argv[2]

# Configure HTTP basic authorization: basic
cm_client.configuration.username = 'admin'
cm_client.configuration.password = 'admin'

# Create an instance of the API class
api_host = 'http://' + cdh_host
port = '7180'
#api_version = 'v41'
# Construct base URL for API
api_url = api_host + ':' + port + '/api/' + api_version
api_client = cm_client.ApiClient(api_url)
cluster_api_instance = cm_client.ClouderaManagerResourceApi(api_client)
#Create API to retrieve cloudera version
api_instance = cm_client.ClustersResourceApi(api_client)
try:
    # Retrieve information about the Cloudera Manager Version
    api_response = api_instance.read_clusters(view='SUMMARY')
    for cluster in api_response.items:
        cloudera_version = cluster.full_version
    # Retrieve information about the Cloudera Manager license.
    api_response = cluster_api_instance.read_license()
    expiration_date = api_response.expiration[0:10]
    expiration_date_dt = datetime.datetime.strptime(expiration_date, "%Y-%m-%d")
    current_date = datetime.datetime.today().strftime('%Y-%m-%d')
    current_date_dt = datetime.datetime.strptime(current_date, "%Y-%m-%d")
    days_left = expiration_date_dt - current_date_dt
    print(str(cdh_host) + ',' + str(cloudera_version) + ',' + str(expiration_date) + ',' + str(days_left.days))
except ApiException as e:
    print(str(cdh_host) + ',' + str(cloudera_version) + ',Cloudera License Expired,-1')

#python Get_License_Expiration_Date.py ilcevfd427 v41
