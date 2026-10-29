#include <iostream>
#include <chrono>
#include <thread>
#include <unistd.h>

int main() {
    std::cout << "[⚙️ Daemon] C++ Service Started (PID: " << getpid() << ")" << std::endl;
    
    int count = 0;
    // 5번만 실행하고 빠져나오도록 제한 (원하는 횟수로 변경 가능)
    while (count < 100) {
        std::cout << "[⚙️ Daemon] Heartbeat #" << ++count << " is alive..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
    
    std::cout << "[⚙️ Daemon] Service Finished. Exiting to Shell..." << std::endl;
    return 0;
}
