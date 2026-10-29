#include <iostream>
#include <chrono>
#include <thread>
#include <unistd.h>
#include <csignal>   // 시그널 처리를 위해 추가
#include <atomic>    // 안전한 플래그 관리를 위해 추가

// 시그널 핸들러에서 안전하게 접근할 수 있도록 atomic 플래그 사용
std::atomic<bool> g_keep_running(true);

// 시스템 종료 시그널을 받았을 때 호출될 함수
void signal_handler(int signum) {
    if (signum == SIGTERM) {
        std::cout << "\n[🚨 Debug] Received SIGTERM (System Poweroff/Shutting down...)" << std::endl;
    } else if (signum == SIGINT) {
        std::cout << "\n[🚨 Debug] Received SIGINT (Ctrl+C interrupted...)" << std::endl;
    }
    
    // 루프를 종료하도록 플래그를 false로 변경
    g_keep_running = false;
}

int main() {
    // 1. 시스템 종료(SIGTERM) 및 Ctrl+C(SIGINT) 시그널 등록
    std::signal(SIGTERM, signal_handler);
    std::signal(SIGINT, signal_handler);

    std::cout << "[⚙️ Daemon] C++ Service Started (PID: " << getpid() << ")" << std::endl;
    
    int count = 0;
    
    // g_keep_running이 true이고 count가 100 미만일 때만 루프 실행
    while (g_keep_running && count < 100) {
        std::cout << "[⚙️ Daemon] Heartbeat #" << ++count << " is alive..." << std::endl;
        
        // 5초를 통째로 쉬면 시그널을 받아도 최대 5초간 반응이 늦어지므로,
        // 100ms 단위로 쪼개서 시그널 상태를 자주 체크합니다 (총 5초 대기).
        for (int i = 0; i < 50; ++i) {
            if (!g_keep_running) break; // 시그널을 받았다면 즉시 대기 루프 탈출
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
    
    // 2. 정리 및 안전한 종료 단계
    std::cout << "[⚙️ Daemon] Cleaning up resources..." << std::endl;
    std::cout << "[⚙️ Daemon] Service Finished. Exiting to Shell..." << std::endl;
    
    return 0;
}
