import reader show BufferedReader
import system.storage
import system.services
import expect show *


// ------------------------------------------------------------------

interface StorageService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="dd9e5fd1-464e-a5e9-b2ef-92bf15ea02ca"
      --major=1
      --minor=0

  // range -> int
  // static RANGE-INDEX     ::= 0
  
  write-to-storage data/string -> bool
  static WRITE-INDEX     ::= 0
  
  delete-from-storage key/string -> bool
  static DELETE-INDEX    ::= 1
  
  delete-all-storage -> bool
  static DELETEALL-INDEX ::= 2

  list-storage -> none
  static LISTALL-INDEX ::= 3

// ------------------------------------------------------------------

class StorageServiceClient extends services.ServiceClient implements StorageService:
  static SELECTOR ::= StorageService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  // range -> int:
  //   return invoke_ StorageService.RANGE-INDEX null

  write-to-storage data/string -> bool:
    return invoke_ StorageService.WRITE-INDEX data

  delete-from-storage key/string -> bool:
    return invoke_ StorageService.DELETE-INDEX key

  delete-all-storage -> bool:
    return invoke_ StorageService.DELETEALL-INDEX null

  list-storage -> none:
    invoke_ StorageService.LISTALL-INDEX null

// ------------------------------------------------------------------

class StorageServiceProvider extends services.ServiceProvider
    implements StorageService services.ServiceHandler:

  // range-last_ := 0

  constructor:
    super "range-sensor" --major=1 --minor=0
    provides StorageService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == StorageService.WRITE-INDEX: return write-to-storage arguments
    if index == StorageService.DELETE-INDEX: return delete-from-storage arguments
    if index == StorageService.DELETEALL-INDEX: return delete-all-storage
    if index == StorageService.LISTALL-INDEX: return list-storage
    unreachable

  // range -> int:
  //   if range-last_ == null:
  //     return -1
  //   else:
  //     return range-last_

  list-storage:
    bucket := storage.Bucket.open --flash "storage-bucket"
    try:
      key  := "log"
      value := bucket.get key
      index := 0
      while value != null:
        bucket.remove key
        key = key + "$(index)"
        value = bucket.get key
        print value
        index++
    finally:
      bucket.close


  write-to-storage data -> bool:
    bucket := storage.Bucket.open --flash "storage-bucket"
    isWritten := false
    try:
      key := "log"
      value := bucket.get key
      index := 0
      while value == null:
        key = key + "$(index)"
        value = bucket.get key
        index++
        
      // print "existing = $value"
      // if value is int: value = value + 1
      // else: value = 0
      bucket[key] = data
      isWritten = true
    finally:
      bucket.close
      return isWritten
    
  delete-from-storage key -> bool:
    isDeleted := false
    bucket := storage.Bucket.open --flash "storage-bucket"

    try:
      bucket.remove key
      expect-throw "key not found": bucket[key]
      isDeleted = true
    finally:
      bucket.close
      return isDeleted
  
  
  delete-all-storage -> bool:
    bucket := storage.Bucket.open --flash "storage-bucket"
    isDeleted := false
    try:
      key  := "log"
      value := bucket.get key
      index := 0
      while value != null:
        bucket.remove key
        key = key + "$(index)"
        value = bucket.get key
        index++
      isDeleted = true
    finally:
      bucket.close
      return isDeleted
      
  
  // main:
  //   bucket := storage.Bucket.open --flash "storage-bucket"
  //   try:
  //     value := bucket.get "log"
  //     print "existing = $value"
  //     if value is int: value = value + 1
  //     else: value = 0
  //     bucket["log"] = value
  //   finally:
  //     bucket.close
      
// main:
//   bucket := storage.Bucket.open --flash "storage-bucket"
//   bucket.remove "log"
//   expect-throw "key not found": bucket["log"]


// createPartrition:
//   region := storage.Region.open --partition "partition-0"
//   expect-throw "ALREADY_IN_USE": storage.Region.open --partition "partition-0"
//   region.close
// import system.storage
