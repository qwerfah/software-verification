show int shared = 1;

active proctype Inc()
{
  show int temp;

  temp = shared;
  temp++;
  shared = temp;
}

active proctype Dec()
{
  show int temp;

  temp = shared;
  temp--;
  shared = temp;
}