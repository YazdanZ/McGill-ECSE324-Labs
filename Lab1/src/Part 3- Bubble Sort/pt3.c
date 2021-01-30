// Initialization
int size = 5;
int array[] = {-1, 23, 0, 12, -7};
int *ptr = &array[0];
  
// Bubble sort algorithm 
for (int step = 0; step < size - 1; step++) {
  for (int i = 0; i < size - step - 1; i++) {
      
    // Sorting in ascending order. 
    // To sort in descending order, change ">" to "<".
    if (*(ptr + i) > *(ptr + i + 1)) {
      // Swap if the larger element is in a later position.
      int tmp = *(ptr + i);
      *(ptr + i) = *(ptr + i + 1);
      *(ptr + i + 1) = tmp;
    }
  }
} 
// Output: Array = {-7,  -1,  0,  12,  23}