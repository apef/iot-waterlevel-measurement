import gpio
import system.services
import system.storage
import dyp_a01 show DYP_A01

import .RangerSensorService
import .LoRAConnectionService
import .StorageService

main:
  m5_tx := 17
  m5_rx := 16
  sensor_tx := 4
  sensor_rx := 3

  // //Device OTAA
  device_eui := "70B3D57ED00656F9"
  app_eui := "0000000000000001"
  app_key := "4DC5446B5A56C2414924C00EFCF19738"

  spawn::
    loraservice := LoraConnectionServiceProvider
    loraservice.install
    task:: loraservice.run m5_tx m5_rx device-eui app_eui app_key
  
  spawn::  
    sensorservice := RangeSensorServiceProvider
    sensorservice.install
    task:: sensorservice.run --tx=sensor_tx --rx=sensor_rx

  // spawn::
  //   storageservice := StorageServiceProvider
  //   storageservice.install
  
  loraclient := LoraConnectionServiceClient
  sensorclient := RangeSensorServiceClient
  // storageclient := StorageServiceClient
  loraclient.open
  sensorclient.open
  // storageclient.open
  
  // (Duration --s=60).periodic:
    // print sensorclient.range
    // dist := sensorclient.range
    // write-to-storage "test"//"$(dist)"
  
  // (Duration --s=300).periodic:

  //   list-storage

  // while true:
  //   print "range = $(loraclient.sendMSG "test") mm"
  //   sleep --ms=1_000
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
    // expect-throw "key not found": bucket[key]
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