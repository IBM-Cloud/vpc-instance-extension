from helper import helper

def main(dict):
    print(dict)
    response = helper(dict)
    return {"results": response}
