show int shared = 1;
show byte mutex;

#define spin_lock(mutex)   \
  do                       \
  :: 1 -> atomic {         \
    if                     \
    :: mutex == 0 ->       \
      mutex = 1;           \
      break                \
    :: else -> skip        \
    fi                     \
  }                        \
  od

#define spin_unlock(mutex) \
  mutex = 0

active proctype Inc()
{
  show int temp;

  spin_lock(mutex);
  temp = shared;
  temp++;
  shared = temp;
  spin_unlock(mutex);
}

active proctype Dec()
{
  show int temp;

  spin_lock(mutex);
  temp = shared;
  temp--;
  shared = temp;
  spin_unlock(mutex);
}