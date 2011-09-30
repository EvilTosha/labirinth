#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <cmath>
#include <vector>

using namespace std;


const int width = 128;
const int height = 36;
const int delta_ceil = 20;
const int delta_floor = 20;

const int ellA[7] = {1, 2, 4, 6, 10, 14, 18};
const int ellB[7] = {1, 5, 9, 15, 24, 36, 53};
const int ellCX[7] =  { 12, 12, 13, 14, 16, 17, 18};


bool inside(int px, int py, int level){
  int a = ellA[level];
  int b = a * 2 - 1;
  int cx = ellCX[level] - 1;
  int cy = width / 2;
  int x = px - cx;
  int y = py - cy;
  return x * x * b * b + y * y * a * a < a * a * b * b;
}

int main(){
  freopen(".out", "w", stdout);
  int field[height][width];
  pair<int, int> p3(11, width / 2), p6(12, width / 2);
  pair<int, int> p1(0, delta_ceil), p2(0, width - delta_ceil);
  pair<int, int> p4(height, delta_floor), p5(height, width - delta_floor);
  int depths[8] = {10, 27, 39, 48, 54, 58, 61, 65};
  for(int x = 0; x < height; ++x){
    for (int y = 0; y < width; ++y){
      //cerr << x + y << endl;
      int d = 0;
      while (d < 7 && !inside( x, y, d ))
        ++d;
      field[x][y] = d;
    }
  }
  for(int x = 0; x < height; ++x){
     // cout << x << " ";
    for (int y = 0; y < width; ++y){
      if (field[x][y] < 7)
        cout << field[x][y] << " ";
      else
        cout << "#" << " ";;
    }
    cout << endl;
  }
  return 0;
}
