package core.common

import chisel3._

object ForwardingStage extends ChiselEnum {
  val SAFE = "b00".U
  val MEM  = "b01".U
  val WB   = "b10".U
}
