#include <iostream>
#include <chrono>
#include <thread>
#include <unistd.h>
#include <csignal>   // 시그널 처리를 위한 헤더 추가
#include <atomic>    // 멀티스레드/시그널 안전한 플래그를 위한 헤더 추가

// 시그널 핸들러와 메인 루프 간의 안전한 통신을 위해 원자적(Atomic) 플래그 사용
std::atomic<bool> keep_running(true);
std::atomic<int> received_signal_num(0);

// 🚨 시그널이 발생했을 때 호출될 핸들러 함수
void signal_handler(int signum) {
    received_signal_num = signum;
    keep_running = false; // 루프 탈출 조건 발동
}

int main() {
    std::cout << "[⚙️ Daemon] C++ Service Started (PID: " << getpid() << ")" << std::endl;
    
    // 🛠️ 시스템 시그널 등록 (핸들러 함수 연결)
    std::signal(SIGINT,  signal_handler); // Ctrl + C 처리 (시그널 번호: 2)
    std::signal(SIGTERM, signal_handler); // 일반적인 kill 요청 처리 (시그널 번호: 15)
    std::signal(SIGUSR2, signal_handler); // 👈 BusyBox poweroff 신호 감지용 추가!

    int count = 0;
    
    // keep_running 플래그가 true인 동안만 작동
    while (keep_running) {
        std::cout << "[⚙️ Daemon] Heartbeat #" << ++count << " is alive..." << std::endl;
        
        // 5초 대기하되, 시그널을 받으면 즉시 깨어나서 탈출할 수 있도록 짧게 쪼개서 대기
        for (int i = 0; i < 50; ++i) {
            if (!keep_running) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
    
    // 🚪 루프를 빠져나온 후 시그널 정보 출력
    std::cout << "\n==========================================" << std::endl;
    std::cout << "[⚠️ Daemon] Signal Received!" << std::endl;
    std::cout << "[⚠️ Daemon] Signal Number: " << received_signal_num << " ";
    
    // 시그널 번호별 친절한 가이드 출력
    switch (received_signal_num) {
        case SIGINT:  std::cout << "(SIGINT - 인터럽트/Ctrl+C)" << std::endl; break;
        case SIGTERM: std::cout << "(SIGTERM - 소프트웨어 종료 요청)" << std::endl; break;
        case SIGUSR2: std::cout << "(SIGUSR2 - poweroff 요청)" << std::endl; break;
        default:      std::cout << "(Unknown Signal)" << std::endl; break;
    }
    std::cout << "[⚙️ Daemon] Cleaning up and Gracefully Shutting Down..." << std::endl;
    std::cout << "==========================================" << std::endl;
    
    return 0;
}
