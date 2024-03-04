// service.toit.
import system.services show ServiceSelector
import system.services show ServiceProvider ServiceHandler
import .service

interface RandomGeneratorService:
  static SELECTOR ::= ServiceSelector
      --uuid="dd9e5fd1-a5e9-464e-b2ef-92bf15ea02ca"
      --major=0
      --minor=1

  generate limit/int -> int
  static GENERATE-INDEX ::= 1

class RandomGeneratorServiceProvider extends ServiceProvider
  implements ServiceHandler:

constructor:
  super "test/random-generator" --major=7 --minor=9
  provides RandomGeneratorService.SELECTOR --handler=this

handle index/int arguments/any --gid/int --client/int -> any:
  if index == RandomGeneratorService.GENERATE-INDEX:
    return generate arguments
  unreachable

generate limit/int -> int:
  print "got request to generate a random number with limit $limit"
  return random limit