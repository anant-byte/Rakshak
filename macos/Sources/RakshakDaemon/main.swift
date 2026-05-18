import Foundation
import RakshakDaemonLib
import os

let log = Logger(subsystem: "com.rakshak.daemon", category: "main")

log.info("Rakshak daemon starting (pid \(getpid()))")
let controller = DaemonController()
controller.start()
RunLoop.main.run()
