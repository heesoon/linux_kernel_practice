#include <iostream>
#include <chrono>
#include <thread>
#include <unistd.h>

int main() {
    std::cout << "[⚙️ Daemon] C++ Service Started (PID: " << getpid() << ")" << std::endl;
    
    int count = 0;
    while (true) {
        std::cout << "[⚙️ Daemon] Heartbeat #" << ++count << " is alive..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
    return 0;
}