import SwiftUI
import ORSSerial
import Foundation

class ContentViewModel: NSObject, ObservableObject, ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {}
    
    // @Published var receivedData: String = ""  // 接收到的数据
    @Published var sendData: String = ""      // 发送的文本框数据
    @Published var btnState: String = "连接设备"      
    @Published var availablePorts: [SerialPort] = []  // 串口设备列表，包含名称和路径
    @Published var selectedPort: SerialPort? = nil    // 当前选中的串口设备
    @Published var progress_cpu: CGFloat = 0.0  // 进度条的状态
    @Published var progress_mem: CGFloat = 0.0  // 进度条的状态
    @Published var progress_disk: CGFloat = 0.0  // 进度条的状态
    
    private var serialPort: ORSSerialPort?
    private var timer: Timer?  // 定时器

    // 用于表示串口设备的结构体
    struct SerialPort: Hashable {
        var name: String   // 串口设备的名称
        var path: String   // 串口设备的路径
    }
    
    // 初始化串口
    func setupSerialPort() {
        
        if(selectedPort == nil){
            return
        }
        
        let port = ORSSerialPort(path: selectedPort?.path ?? "")  // 替换为实际的串口路径
        port?.baudRate = 115200
        port?.parity = .none
        port?.numberOfDataBits = 8
        port?.numberOfStopBits = 1
        port?.delegate = self  // 设置串口代理
        self.serialPort = port
        
        // 打开串口
        serialPort?.open()
        if(serialPort?.isOpen == true)
        {
            btnState = "已连接"
        }
        else
        {
            btnState = "连接设备"
        }
    }

    // 发送数据到串口
    func sendDataToSerialPort(data: String) {
        
        if(serialPort?.isOpen != true)
        {
            return
        }
        
        guard let port = serialPort else {
            print("Serial port is not available.")
            return
        }

        if let data = data.data(using: .utf8) {
            port.send(data)  // 发送数据到串口
            print("Sending data: \(data)")
        }
    }

    // 串口代理方法，接收数据
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
//        if let receivedString = String(data: data, encoding: .utf8) {
//            DispatchQueue.main.async {
//                self.receivedData += receivedString
//            }
//        }
    }

    // 执行Top命令获取Cpu信息
    func runTopCommand() -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-l", "2" ,"-n" ,"0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            print("Failed to run top command: \(error)")
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        return output
    }
    
    // 执行Top命令获取Cpu信息
    func InitTtyList() {
        // 获取所有可用串口设备
        let ports = ORSSerialPortManager.shared().availablePorts
        self.availablePorts = ports.map { port in
            SerialPort(name: port.name, path: port.path)
        }
    }

//    // 解析Top命令返回的字符串 获取cpu使用情况
//    func parseCPUUsage(from text: String) -> (user: Float, sys: Float, idle: Float)? {
//        let cpuUsagePattern = "CPU usage: ([0-9.]+)% user, ([0-9.]+)% sys, ([0-9.]+)% idle"
//        let regex = try? NSRegularExpression(pattern: cpuUsagePattern)
//        if let match = regex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
//            if let userRange = Range(match.range(at: 1), in: text),
//               let sysRange = Range(match.range(at: 2), in: text),
//               let idleRange = Range(match.range(at: 3), in: text) {
//                let user = Float(text[userRange]) ?? 0
//                let sys = Float(text[sysRange]) ?? 0
//                let idle = Float(text[idleRange]) ?? 0
//                return (user, sys, idle)
//            }
//        }
//        return nil
//    }
    
    
    // 解析Top命令返回的字符串 获取cpu使用情况
    func parseCPUUsage(from text: String) -> (user: Float, sys: Float, idle: Float)? {
        // 正则表达式匹配 CPU 使用率
        let cpuUsagePattern = "CPU usage: ([0-9.]+)% user, ([0-9.]+)% sys, ([0-9.]+)% idle"
        
        // 使用 NSRegularExpression 查找所有匹配的结果
        let regex = try? NSRegularExpression(pattern: cpuUsagePattern)
        
        // 查找所有匹配的范围
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        // 如果有匹配项，获取最后一个
        if let lastMatch = matches?.last {
            if let userRange = Range(lastMatch.range(at: 1), in: text),
               let sysRange = Range(lastMatch.range(at: 2), in: text),
               let idleRange = Range(lastMatch.range(at: 3), in: text) {
                
                // 提取数字并转换为 Float
                let user = Float(text[userRange]) ?? 0
                let sys = Float(text[sysRange]) ?? 0
                let idle = Float(text[idleRange]) ?? 0
                
                return (user, sys, idle)
            }
        }
        
        return nil
    }

    // 获取内存使用情况
    func getMemoryUsage() -> (used: UInt64, total: UInt64)? {
        // 获取总内存大小
        var totalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0) != 0 {
            print("Error: \(errno)")
            return nil
        }
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: vmStats) / MemoryLayout<integer_t>.size)
        let HOST_VM_INFO64: host_flavor_t = Int32(HOST_VM_INFO64)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result != KERN_SUCCESS {
            print("Error: \(result)")
            return nil
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        _ = UInt64(vmStats.free_count) * pageSize
        let activeMemory = UInt64(vmStats.active_count) * pageSize
        let inactiveMemory = UInt64(vmStats.inactive_count) * pageSize
        let wiredMemory = UInt64(vmStats.wire_count) * pageSize
        
        let usedMemory = activeMemory + inactiveMemory + wiredMemory
        return (used: usedMemory, total: totalMemory)
    }

     
    func getDiskUsage() -> (used: UInt64, total: UInt64)? {
        let fileManager = FileManager.default
        do {
            let homeDirectoryURL = try fileManager.url(for: .userDirectory, in: .localDomainMask, appropriateFor: nil, create: false)
            let values = try homeDirectoryURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            
            if let totalCapacity = values.volumeTotalCapacity, let availableCapacity = values.volumeAvailableCapacity {
                let usedCapacity = totalCapacity - availableCapacity
                return (used: UInt64(usedCapacity), total: UInt64(totalCapacity))
            }
        } catch {
            print("Error retrieving disk usage: \(error.localizedDescription)")
            return nil
        }
        return nil
    }
  
    // 更新系统信息并发送
    func updateAndSendSystemInfo() {
        if let systemInfo = runTopCommand() {
            print("System Usage Info:")
            print(systemInfo)
              
            // 提取并打印 CPU 占用率
            var cpuUsage_v = 0
            // 提取并打印内存占用率
            var memoryUsage_v = 0
            // 提取并打印硬盘使用率
            var diskUsage_v = 0
              
            if let cpuUsage = parseCPUUsage(from: systemInfo) {
                cpuUsage_v = Int(cpuUsage.user + cpuUsage.sys)
                self.progress_cpu = CGFloat(cpuUsage_v)
            }
            
            if let memoryUsage = getMemoryUsage() {
                let usedMemoryGB = Double(memoryUsage.used) / 1_073_741_824.0 // Convert bytes to GB
                let totalMemoryGB = Double(memoryUsage.total) / 1_073_741_824.0
                let memoryUsagePercentage = (usedMemoryGB / totalMemoryGB) * 100.0

                memoryUsage_v = Int(memoryUsagePercentage)
                self.progress_mem = CGFloat(memoryUsage_v)
            } else {
                print("Failed to retrieve memory usage information")
            }
            
            
            if let diskUsage = getDiskUsage() {
                let usedDiskGB = Double(diskUsage.used) / 1_073_741_824.0 // Convert bytes to GB
                let totalDiskGB = Double(diskUsage.total) / 1_073_741_824.0
                let diskUsagePercentage = (usedDiskGB / totalDiskGB) * 100.0
                diskUsage_v = Int(diskUsagePercentage)
                
                self.progress_disk = CGFloat(diskUsage_v)
                print(String(format: "Disk Usage: %.2f%% (Used: %.2f GB, Total: %.2f GB)", diskUsagePercentage, usedDiskGB, totalDiskGB))
            } else {
                print("Failed to retrieve disk usage information")
            }
            
            
            // 格式化并发送数据
            let infoString = String(format: "%d,%d,%d", memoryUsage_v,diskUsage_v,cpuUsage_v)
            sendDataToSerialPort(data: infoString)
            
        } else {
            print("Failed to run top command.")
        }
    }

    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        print("Serial port opened.")
    }

    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        print("Serial port closed.")
    }

    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    // 启动定时任务
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.updateAndSendSystemInfo()
        }
    }
    
    // 停止定时任务
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

