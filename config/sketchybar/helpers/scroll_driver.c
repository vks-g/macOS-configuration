// scroll_driver — keeps SketchyBar's scrolling names moving without pauses.
//
// SketchyBar only (re)starts a text scroll when the item receives an update, so
// this sends "--trigger <event>" to SketchyBar every <interval> microseconds.
// Items subscribed to that event restart their scroll the moment it finishes.
// All three names are kicked off by the same trigger, so they start in sync.
//
// Local mach IPC to SketchyBar only — no network, no files, no permissions.
// Exits on its own when the SketchyBar process it was started for goes away.
//
// Build: clang -O2 -o scroll_driver scroll_driver.c
// Usage: scroll_driver <event> <interval_us> <sketchybar_pid>

#include <bootstrap.h>
#include <errno.h>
#include <signal.h>
#include <mach/mach.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct message {
  mach_msg_header_t header;
  mach_msg_size_t descriptor_count;
  mach_msg_ool_descriptor_t descriptor;
};

static mach_port_t lookup_sketchybar(void) {
  mach_port_t bootstrap, port;
  if (task_get_special_port(mach_task_self(), TASK_BOOTSTRAP_PORT, &bootstrap) != KERN_SUCCESS)
    return MACH_PORT_NULL;
  if (bootstrap_look_up(bootstrap, "git.felix.sketchybar", &port) != KERN_SUCCESS)
    return MACH_PORT_NULL;
  return port;
}

int main(int argc, char** argv) {
  const char* event = argc > 1 ? argv[1] : "scroll_tick";
  useconds_t interval = argc > 2 ? (useconds_t)atoi(argv[2]) : 16000;
  if (interval < 8000) interval = 8000;
  pid_t sketchybar_pid = argc > 3 ? (pid_t)atoi(argv[3]) : 0;

  // Same wire format as the sketchybar CLI: NUL-separated args, extra NUL at the end
  char payload[256] = { 0 };
  size_t event_len = strnlen(event, 200);
  memcpy(payload, "--trigger", 9);
  memcpy(payload + 10, event, event_len);
  uint32_t payload_len = (uint32_t)(10 + event_len + 2);

  mach_port_t port = MACH_PORT_NULL;
  for (;;) {
    if (sketchybar_pid > 0 && kill(sketchybar_pid, 0) != 0 && errno == ESRCH)
      return 0;  // SketchyBar exited

    if (port == MACH_PORT_NULL) {
      port = lookup_sketchybar();
      if (port == MACH_PORT_NULL) { sleep(1); continue; }
    }

    struct message msg = { 0 };
    msg.header.msgh_remote_port = port;
    msg.header.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0, 0, MACH_MSGH_BITS_COMPLEX);
    msg.header.msgh_size = sizeof(msg);
    msg.descriptor_count = 1;
    msg.descriptor.address = payload;
    msg.descriptor.size = payload_len;
    msg.descriptor.copy = MACH_MSG_VIRTUAL_COPY;
    msg.descriptor.deallocate = false;
    msg.descriptor.type = MACH_MSG_OOL_DESCRIPTOR;

    kern_return_t kr = mach_msg(&msg.header, MACH_SEND_MSG | MACH_SEND_TIMEOUT, sizeof(msg), 0,
                                MACH_PORT_NULL, 100, MACH_PORT_NULL);
    if (kr != MACH_MSG_SUCCESS) {  // SketchyBar restarted or busy: look it up again
      mach_port_deallocate(mach_task_self(), port);
      port = MACH_PORT_NULL;
      sleep(1);
      continue;
    }
    usleep(interval);
  }
}
