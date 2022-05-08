show int shared = 1;

active proctype Inc()
{
  show int temp;

  atomic {
    temp = shared;
    temp++;
    shared = temp;
  }
}

active proctype Dec()
{
    show int temp;

  atomic {
    temp = shared;
    temp--;
    shared = temp;
  }
}