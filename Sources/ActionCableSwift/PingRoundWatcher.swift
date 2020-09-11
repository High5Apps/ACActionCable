//
//  File.swift
//  
//
//  Created by Julian Tigler on 9/11/20.
//

import Foundation

public final class PingRoundWatcher {


    weak var client: ACClient?
    var pingLimit: Int64 = 6
    var finish: Bool = false
    var checksDelay: Float32 {
        get { Float32(_checksDelay) / 1_000_000 }
        set { _checksDelay = UInt32(newValue * 1_000_000) }
    }
    private var _checksDelay: UInt32 = 500_000
    private var lastTimePoint: Int64 = 0
    private var started: Bool = false
    private let lock: NSLock = .init()
    private let startInfoLock: NSLock = .init()


    init(client: ACClient? = nil) {
        self.client = client
    }

    func start() {
        if isStarted() { return }

        Thread { [weak self] in
            guard let self = self else { return }
            self.setFinish(to: false)
            self.setStarted(to: true)
            self.updateLastPoint()
            while !self.finish {
                if !self.isConnected() {
                    self.client?.disconnect()
                    usleep(200_000)
                    self.client?.connect()
                    usleep(self._checksDelay)
                    self.updateLastPoint()
                    continue
                }
                if self.isWorks() {
                    usleep(self._checksDelay)
                    continue
                } else {
                    self.lock.lock()
                    self.client?.setIsConnected(to: false)
                    self.lock.unlock()
                    usleep(self._checksDelay)
                }
            }
            self.setStarted(to: false)
        }.start()
    }
    
    public func stop() {
        setFinish(to: true)
    }

    public func ping() {
        updateLastPoint()
    }

    private func updateLastPoint() {
        lock.lock()
        lastTimePoint = Date().toSeconds()
        lock.unlock()
    }

    public func isStarted() -> Bool {
        startInfoLock.lock()
        let result: Bool = started
        startInfoLock.unlock()

        return result
    }

    private func setStarted(to: Bool) {
        startInfoLock.lock()
        started = to
        startInfoLock.unlock()
    }

    private func isConnected() -> Bool {
        self.client?.getIsConnected() ?? false
    }

    private func setFinish(to: Bool) {
        lock.lock()
        finish = to
        lock.unlock()
    }

    private func isWorks() -> Bool {
        lock.lock()
        let result: Bool = !self.isOldPing()
        lock.unlock()
        return result
    }

    private func isOldPing() -> Bool {
        (Date().toSeconds() - lastTimePoint) >= pingLimit
    }
}
