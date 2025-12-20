package core.common

import chisel3._

object ALUOp extends ChiselEnum {
  val ADD  = 0.U(4.W)
  val SUB  = 1.U(4.W)
  val SLL  = 2.U(4.W)
  val SLT  = 3.U(4.W)
  val SLTU = 4.U(4.W)
  val XOR  = 5.U(4.W)
  val SRL  = 6.U(4.W)
  val SRA  = 7.U(4.W)
  val OR   = 8.U(4.W)
  val AND  = 9.U(4.W)
}

object MemOp extends ChiselEnum {
  val LB  = 0.U(3.W)
  val LH  = 1.U(3.W)
  val LW  = 2.U(3.W)
  val LBU = 3.U(3.W)
  val LHU = 4.U(3.W)
  val SB  = 5.U(3.W)
  val SH  = 6.U(3.W)
  val SW  = 7.U(3.W)
}
