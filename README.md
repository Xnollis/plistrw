# plistrw
## Description:
    This is a command line tool to READ & WRITE key-value from a Mac PLIST file.
    
    A KeyPath string is used for describing the exact location of an object. 
    
    By using KeyPath string , we can read/change/add/delete value of specific object in command line or TTY.

    It's designed to work on Mac OS X , and the project could be built with Xcode 9.x.
## Usage:
plistrw <PList_file> <Key1[n1]/Key2[n2]...> [NewValue] [-]

## Read Value Example:
plistrw a.plist objkey1/objkey2/obj_array[3]/key3

## Write Value Example:
1. Overwirte/AddNewValue to a Dictionary Item:

    > plistrw a.plist objkey1/objkey2 another_new_value
2. Overwirte existing item value in an Array:

    > plistrw a.plist uplevel_key_n/obj_arrayname[item_index1][....][item_index_n] another_new_value
3. Append New Item with new value to an Array(only available when "obj_arrayname" is an Array):

    > plistrw a.plist uplevel_key_n/obj_arrayname[] another_new_value
4. Create an Array Object and set it as a subitem:

    Use a json string as the <NewValue>, just like this:
  
    > plistrw a.plist uplevel_key_n/obj_arrayname "[123,145,167]"
5. Set item value as a BOOL type value:

    > plistrw a.plist uplevel_key_n/obj_name BOOL_TRUE|BOOL_FALSE
6. Set item value with Binary bytes value:

    > plistrw a.plist uplevel_key_n/obj_name "<7C8D9EF1A3>" ("<>"is required and content length must be 2n Bytes)
7. Remove a Dictrionary or an Array Item:

    By using "-" as the last param , an specific item could be removed:
    
    > plistrw a.plist uplevel_key_n/obj_itemname -
    
    > plistrw a.plist uplevel_key_n/obj_arrayname[item_index_n] -
8. Change an object's type should set JSON string as new value to the Object.

    > plistrw a.plist full_keypath_to_object "[123,145]"
    
    this is to set and change the value and type to an Array object.
    
    > plistrw a.plist full_keypath_to_object "{\\\"key1\\\":\\\"obj1\\\"}"
    
    this is to set and change the value and type to an Dictionary object.

## Skills:
1. Use json string as the <NewValue> param to create/set a complex value at one time:
  
    > plistrw a.plist uplevel_key_n/obj_name "{\\\"key1\\\":\\\"obj1\",\\\"key2\\\":{\\\"subkey1\\\":\\\"subobj1\\\"},\\\"array_obj1\\\":[1234,1456,1678]}"
2. Use "--plist_template" as the only one param to print a plist file template.
3. It's strongly recommended to use single quotation marks ('), or double quotation marks (") to quote each param in order to get expected correct operation result.
## Copyright
Copyright Xnollis, 2018, ShangHai.
