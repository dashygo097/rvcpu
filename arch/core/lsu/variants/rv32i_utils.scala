package arch.core.lsu

class RV32ILSUUtilitiesImpl extends LSUUtilities with RV32ILSUConsts {}

object RV32ILSUUtilities extends RegisteredLSUUtilities with RV32ILSUConsts {
  override def isaName: String     = "rv32i"
  override def utils: LSUUtilities = new RV32ILSUUtilitiesImpl
}
