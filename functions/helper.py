from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_sdk_core import ApiException
from json import JSONDecoder

service = None
# Main entry function 
def helper(params):
    authenticator = IAMAuthenticator(
    params["IAM_API_KEY"])
    global service 
    service = VpcV1('2020-06-02', authenticator=authenticator)
    response = get_instance_id(params)
    return response

# To extract JSON objects from the incoming activity tracker with LogDNA alert
def extract_json_objects(text, decoder=JSONDecoder()):
    pos = 0
    while True:
        match = text.find('{', pos)
        if match == -1:
            break
        try:
            result, index = decoder.raw_decode(text[match:])
            yield result
            pos = match + index
        except ValueError:
            pos = match + 1

# Get the network interface ID associated with an Instance(VSI)
def get_network_interface_id(instance_Id):
    # Get instance
    try:
        instance = service.get_instance(
        id=instance_Id
         ).get_result()
    except ApiException as e:
        print("Get instance failed with status code " +
          str(e.code) + ": " + e.message)
    return instance['network_interfaces'][0]['id']

# Get an unbound floating IP. If none exists, create a new floating IP
def get_floating_ip_id(fip_name,zone):
    print("List Floating IPs")
    try:
        floating_ips = service.list_floating_ips().get_result()['floating_ips']
    except ApiException as e:
        print("List floating IPs failed with status code " + str(e.code) + ": " + e.message)
    unassigned_fip_List=[]
    floating_ip_id=""
    key='target'
    for floating_ip in floating_ips:
        if key not in floating_ip:
            unassigned_fip_List.append(floating_ip['id'])
    if not unassigned_fip_List:
        zone_identity_model = {}
        zone_identity_model['name'] = zone

        # Construct a dict representation of a FloatingIPPrototypeFloatingIPByZone model
        floating_ip_prototype_model = {}
        floating_ip_prototype_model["name"] = fip_name

        # floating_ip_prototype_model['resource_group'] = resource_group_identity_model
        floating_ip_prototype_model["zone"] = zone_identity_model
        
        # Set up parameter values
        floating_ip_prototype = floating_ip_prototype_model

        # Invoke method
        print("Reserve Floating IP")
        try:
            ip = service.create_floating_ip(
                floating_ip_prototype=floating_ip_prototype, headers={}).get_result()
        except ApiException as e:
            print("Create Floating IP failed with status code " +
                str(e.code) + ": " + e.message)
        floating_ip_id=ip['id']
    else:
        floating_ip_id=unassigned_fip_List[0]    
    
    print("A floating IP is created with an id:",floating_ip_id)
    return floating_ip_id

# Reserve the floating IP to the provisioned instance
def add_instance_floating_ip(instance_id, network_interface_id,zone):
    # Reserve a floating IP
    floating_ip_id=get_floating_ip_id(instance_id.split('-')[-1]+"-floating-ip",zone)
    try:
        response = service.add_instance_network_interface_floating_ip(
        instance_id=instance_id,
        network_interface_id=network_interface_id,
        id=floating_ip_id
        ).get_result()
    except ApiException as e:
        print("Attaching floating IP to the instance failed with status code " + str(e.code) + ": " + e.message)
    return response

# Get the instance ID of the provisioned VSI
def get_instance_id(dict):
    finalResponse=[]
    for result in extract_json_objects(dict['lines']):
        try:
            instance_Id=result['_app'][result['_app'].find('instance:')+9:]
            instance_Id=instance_Id.replace(" ","")
            zone=result['_app'].split(':')[5]
            network_interface_id=get_network_interface_id(instance_Id)
            response=add_instance_floating_ip(instance_Id,network_interface_id,zone)
            finalResponse.append(response)
        except:
            continue
    return finalResponse
