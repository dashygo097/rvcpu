package arch.core.decoder

import arch.core.common.Consts
import arch.core.alu.RV32IALUConsts
import arch.core.lsu.RV32ILSUConsts
import chisel3.util.BitPat

trait RV32IDecodeConsts extends Consts with RV32IALUConsts with RV32ILSUConsts {
  // Branch
  def BR_X   = BitPat("b???")
  val SZ_BR  = BR_X.getWidth
  def BR_EQ  = BitPat("b000")
  def BR_NE  = BitPat("b001")
  def BR_J   = BitPat("b010")
  def BR_N   = BitPat("b011")
  def BR_LT  = BitPat("b100")
  def BR_GE  = BitPat("b101")
  def BR_LTU = BitPat("b110")
  def BR_GEU = BitPat("b111")

  // Immediate
  def IMM_X  = BitPat("b???")
  val SZ_IMM = IMM_X.getWidth
  def IMM_I  = BitPat("b000")
  def IMM_S  = BitPat("b001")
  def IMM_B  = BitPat("b010")
  def IMM_U  = BitPat("b011")
  def IMM_J  = BitPat("b100")
}
