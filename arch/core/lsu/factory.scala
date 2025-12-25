package arch.core.lsu

import scala.collection.mutable

object LSUUtilitiesFactory {
  private val registry = mutable.Map[String, LSUUtilities]()

  def register(name: String, sigs: LSUUtilities): Unit =
    registry(name.toLowerCase) = sigs

  def get(name: String): Option[LSUUtilities] =
    registry.get(name.toLowerCase)

  def getOrElse(name: String, default: LSUUtilities): LSUUtilities =
    registry.getOrElse(name.toLowerCase, default)

  def listAvailable(): Seq[String] = registry.keys.toSeq.sorted

  def contains(name: String): Boolean = registry.contains(name.toLowerCase)
}

trait RegisteredLSUUtilities {
  def isaName: String
  def utils: LSUUtilities
  LSUUtilitiesFactory.register(isaName, utils)
}

object LSUInit {
  val rv32iUtils = RV32ILSUUtilities
}
