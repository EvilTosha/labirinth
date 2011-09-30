#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <cmath>
#include <vector>

using namespace std;

bool overLine(pair<int, int> p1, pair<int, int> p2, pair<int, int> p){
  return (p1.second - p2.second) * p.first + (p2.first - p1.first) * p.second >
    -(p1.first * p2.second - p2.first * p1.second);
}

const int width = 128;
const int height = 36;
const int delta_ceil = 20;
const int delta_floor = 20;

int main(){
  // freopen(".out", "w", stdout);
  int field[height][width];
  pair<int, int> p3(11, width / 2), p6(12, width / 2);
  pair<int, int> p1(0, delta_ceil), p2(0, width - delta_ceil);
  pair<int, int> p4(height, delta_floor), p5(height, width - delta_floor);
  int depths[8] = {10, 27, 39, 48, 54, 58, 61, 65};
  for(int x = 0; x < height; ++x){
    for (int y = 0; y < width; ++y){
      pair<int, int> p(x, y);
      //cerr << x + y << endl;
      if (!overLine(p2, p3, p) && !overLine(p3, p1, p))
        field[x][y] = 0;
      else if (overLine(p6, p4, p) && overLine(p5, p6, p))
        field[x][y] = 0;
      else{
        int wall = min(y, width - y);
        int d = 0;
        while (wall > depths[d])
          ++d;
        field[x][y] = d + 1;
      }
    }
  }
  for (int i = 0; i < height; ++i){
    for (int j = 0; j < width; ++j){
      if (field[i][j] == 0)
        field[i][j] = field[i][j - 1];
    }
  }
  for(int x = 0; x < height; ++x){
    cout << x << " ";
    for (int y = 0; y < width; ++y){
      cout << field[x][y];
    }
    cout << endl;
  }
  return 0;
}
