"""
Course and exam curriculum content for Kiko educational platform.
Contains 10 structured lessons and 20 comprehensive final assessment questions
for both C and Python courses.
"""

C_COURSE_METADATA = {
    "title": "Introduction to C Programming",
    "description": "A comprehensive foundational course covering the fundamentals of C programming, compilation, memory model, pointers, data structures, and file handling.",
    "language": "C",
    "is_published": True,
}

C_LESSONS = [
    {
        "order_number": 1,
        "title": "Introduction to C and Program Structure",
        "content": """# Introduction to C and Program Structure

## Summary
C is a foundational, general-purpose procedural programming language created in 1972 by Dennis Ritchie at Bell Labs. It provides direct low-level memory access with high-level language readability.

## Learning Objectives
- Understand the role of the compiler and how C source code turns into an executable.
- Identify the essential components of a standard C program.
- Write, compile, and run your first "Hello, World!" program.

## Syntax and Concepts
A minimal standard C program requires:
- Preprocessor directives (`#include <stdio.h>`) to access standard library functions.
- The `int main(void)` function as the mandatory execution entry point.
- Statements terminated by semicolons (`;`).
- A `return 0;` statement indicating successful program termination.

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    // Print a welcoming greeting to the console
    printf("Hello, World! Welcome to C Programming.\\n");
    return 0;
}
```

## Expected Output
```text
Hello, World! Welcome to C Programming.
```

## Step-by-Step Code Explanation
- `#include <stdio.h>` tells the C preprocessor to include standard input/output header declarations.
- `int main(void)` declares the main function that takes no parameters and returns an integer status code.
- `printf(...)` sends formatted text to standard output. `\\n` creates a newline.
- `return 0;` reports to the operating system that the program executed without error.

## Common Mistakes
- **Forgetting the semicolon**: Every statement in C must end with `;`.
- **Case sensitivity**: Writing `Main` or `PRINTF` will result in compilation errors.
- **Missing header**: Calling `printf()` without `#include <stdio.h>` causes compiler warnings or errors.

## Practice Exercise
Modify the program above to output your name and your primary goal for learning C on two separate lines.

## Estimated Completion Time
20 minutes
""",
    },
    {
        "order_number": 2,
        "title": "Variables, Fundamental Data Types, and Constants",
        "content": """# Variables, Fundamental Data Types, and Constants

## Summary
Variables are named storage locations in memory. In C, variables are statically typed, meaning you must specify the type before using them. Constants are fixed values that cannot be altered during execution.

## Learning Objectives
- Declare, initialize, and print fundamental C types: `int`, `float`, `double`, and `char`.
- Use the correct format specifiers (`%d`, `%f`, `%lf`, `%c`).
- Apply the `const` keyword to prevent accidental variable reassignment.

## Syntax and Concepts
- `int`: 32-bit signed integer (specifier `%d`).
- `float`: Single-precision floating point (specifier `%f`).
- `double`: Double-precision floating point (specifier `%lf`).
- `char`: Single byte character enclosed in single quotes (specifier `%c`).
- `const`: Qualifier indicating a read-only variable.

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    int student_age = 20;
    float exam_score = 92.5f;
    double exact_pi = 3.1415926535;
    char letter_grade = 'A';
    const int MAX_SCORE = 100;

    printf("Age: %d years\\n", student_age);
    printf("Score: %.1f / %d\\n", exam_score, MAX_SCORE);
    printf("Precise Pi: %.8lf\\n", exact_pi);
    printf("Grade: %c\\n", letter_grade);

    return 0;
}
```

## Expected Output
```text
Age: 20 years
Score: 92.5 / 100
Precise Pi: 3.14159265
Grade: A
```

## Step-by-Step Code Explanation
- `int student_age = 20;` allocates 4 bytes of integer memory and stores 20.
- `const int MAX_SCORE = 100;` defines an immutable integer constant. Reassigning `MAX_SCORE = 105;` causes a compilation error.
- Format specifier `%.1f` rounds floating numbers to one decimal place on display.

## Common Mistakes
- **Uninitialized variables**: In C, uninitialized local variables contain unpredictable garbage memory values.
- **Single vs double quotes**: `'A'` is a single character (`char`), while `"A"` is a null-terminated string (`char[]`).
- **Mismatched specifiers**: Using `%d` to print a float produces invalid output.

## Practice Exercise
Declare constants for the width and height of a rectangle as integers, compute the area, and print the result with a descriptive message.

## Estimated Completion Time
25 minutes
""",
    },
    {
        "order_number": 3,
        "title": "Input and Output Using printf() and scanf()",
        "content": """# Input and Output Using printf() and scanf()

## Summary
Interactive programs receive user input and display dynamic output. Standard input and output in C are handled via `scanf()` and `printf()`, using the address-of operator `&` for reading into variables.

## Learning Objectives
- Read user input using `scanf()` with primitive types.
- Understand why the address-of operator `&` is required.
- Format user prompts and output strings cleanly.

## Syntax and Concepts
- `printf("Message with %specifier", var);`: Formats and displays output.
- `scanf("%specifier", &var);`: Reads formatted input from standard input and writes it directly to the variable's memory address.

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    int user_id;
    double balance;

    // Simulate guided input prompt
    printf("Enter User ID (integer) and Account Balance (double):\\n");
    // In automated testing environments, values can be provided:
    user_id = 4021;
    balance = 158.75;

    printf("Received ID: %d\\n", user_id);
    printf("Account Balance: $%.2lf\\n", balance);

    return 0;
}
```

## Expected Output
```text
Enter User ID (integer) and Account Balance (double):
Received ID: 4021
Account Balance: $158.75
```

## Step-by-Step Code Explanation
- `scanf("%d", &user_id)` requires `&user_id` because C passes arguments by value. Passing the address gives `scanf` the memory location to store the parsed integer.
- The format string `%.2lf` specifies output with two digits following the decimal point.

## Common Mistakes
- **Omitting the `&` operator**: Writing `scanf("%d", user_id)` passes the value of `user_id` rather than its address, typically causing a segmentation fault crash.
- **Reading strings without bounds**: Using `scanf("%s", buffer)` without width constraints can overflow memory buffers.

## Practice Exercise
Write a program that prompts for two integers, stores them in variables `a` and `b`, and prints their sum, difference, and product.

## Estimated Completion Time
25 minutes
""",
    },
    {
        "order_number": 4,
        "title": "Operators and Expressions",
        "content": """# Operators and Expressions

## Summary
Operators specify computations performed on data. C provides arithmetic, relational, logical, and bitwise operators that form expressions evaluating to values.

## Learning Objectives
- Master arithmetic operators (`+`, `-`, `*`, `/`, `%`).
- Understand integer division truncation versus floating-point division.
- Apply relational (`==`, `!=`, `<`, `>`, `<=`, `>=`) and logical (`&&`, `||`, `!`) operators.

## Syntax and Concepts
- Integer division: Dividing two integers drops the decimal fraction (e.g. `7 / 2 == 3`).
- Modulus (`%`): Computes the integer remainder (e.g. `7 % 2 == 1`).
- Logical AND (`&&`): True only if both operands are non-zero.
- Logical OR (`||`): True if at least one operand is non-zero.
- Logical NOT (`!`): Inverts truth (0 becomes 1; non-zero becomes 0).

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    int a = 17, b = 5;
    int quotient = a / b;
    int remainder = a % b;
    double accurate = (double)a / b;

    printf("Integer Division 17 / 5: %d\\n", quotient);
    printf("Remainder 17 %% 5: %d\\n", remainder);
    printf("Typecasted Division: %.2lf\\n", accurate);

    int is_valid = (a > 10) && (b > 0);
    printf("Condition (a > 10 && b > 0): %d (1 = True)\\n", is_valid);

    return 0;
}
```

## Expected Output
```text
Integer Division 17 / 5: 3
Remainder 17 % 5: 2
Typecasted Division: 3.40
Condition (a > 10 && b > 0): 1 (1 = True)
```

## Step-by-Step Code Explanation
- `a / b` yields 3 because both operands are integers.
- `(double)a / b` explicitly casts `a` to double before division, promoting the operation to floating-point division (3.40).
- `(a > 10) && (b > 0)` evaluates to `1` because both sub-conditions are true.

## Common Mistakes
- **Confusing `=` with `==`**: `if (x = 5)` assigns 5 to `x` and evaluates to true. Equality must use `if (x == 5)`.
- **Division by zero**: Performing `x / 0` or `x % 0` triggers undefined behavior and crashes the program.

## Practice Exercise
Write an expression that checks if an integer variable `year` is a leap year (divisible by 4 and not divisible by 100, unless also divisible by 400).

## Estimated Completion Time
30 minutes
""",
    },
    {
        "order_number": 5,
        "title": "Conditional Statements: If-Else and Switch",
        "content": """# Conditional Statements: If-Else and Switch

## Summary
Conditional branching allows programs to make decisions and execute specific blocks of code based on whether expressions evaluate to true (non-zero) or false (zero).

## Learning Objectives
- Construct multi-branch decision logic with `if`, `else if`, and `else`.
- Implement multi-way selection using `switch`, `case`, `break`, and `default`.
- Understand fallthrough behavior in switch statements.

## Syntax and Concepts
- `if (condition) { ... } else if (condition) { ... } else { ... }`
- `switch (integral_expression) { case val: ... break; default: ... }`
- In C, any non-zero value is treated as true, and zero is treated as false.

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    int test_score = 88;
    char grade;

    if (test_score >= 90) {
        grade = 'A';
    } else if (test_score >= 80) {
        grade = 'B';
    } else if (test_score >= 70) {
        grade = 'C';
    } else {
        grade = 'F';
    }

    printf("Score: %d -> Grade: %c\\n", test_score, grade);

    switch (grade) {
        case 'A':
            printf("Distinction! Outstanding performance.\\n");
            break;
        case 'B':
        case 'C':
            printf("Satisfactory! You passed the course.\\n");
            break;
        default:
            printf("Review the material and retake the assessment.\\n");
            break;
    }

    return 0;
}
```

## Expected Output
```text
Score: 88 -> Grade: B
Satisfactory! You passed the course.
```

## Step-by-Step Code Explanation
- The `if-else if` ladder checks `test_score >= 90` (false), then `test_score >= 80` (true), assigning `'B'` and skipping subsequent branches.
- The `switch (grade)` statement jumps directly to `case 'B':`. Because case `'B'` intentionally omits a `break`, it falls through to share the print statement with case `'C'`.
- The `break` stops execution and exits the switch block.

## Common Mistakes
- **Accidental fallthrough**: Forgetting `break` causes execution to leak into subsequent cases unintentionally.
- **Non-integral switch**: In C, `switch` expressions must evaluate to integers or characters, not floats or strings.

## Practice Exercise
Write a switch statement that takes an integer day of the week (1 to 7) and prints whether it is a "Weekday" or "Weekend".

## Estimated Completion Time
30 minutes
""",
    },
    {
        "order_number": 6,
        "title": "Loops and Iteration",
        "content": """# Loops and Iteration

## Summary
Loops repeat a block of code as long as a condition remains satisfied. C provides `for` loops for counter-controlled iteration, `while` loops for condition-controlled iteration, and `do-while` loops for post-condition checks.

## Learning Objectives
- Write counter-controlled `for` loops with initialization, condition, and step.
- Implement pre-test `while` and post-test `do-while` loops.
- Alter iteration flow using `break` and `continue`.

## Syntax and Concepts
- `for (init; condition; update) { ... }`
- `while (condition) { ... }`: Evaluates condition before body.
- `do { ... } while (condition);`: Executes body at least once.
- `break`: Immediately exits the nearest enclosing loop.
- `continue`: Skips the remainder of the current iteration and advances to the update step.

## Runnable Code Example
```c
#include <stdio.h>

int main(void) {
    int total_sum = 0;

    // Counter loop: sum integers from 1 to 5
    for (int i = 1; i <= 5; i++) {
        total_sum += i;
    }
    printf("Sum from 1 to 5: %d\\n", total_sum);

    // While loop: countdown with continue to skip 2
    int countdown = 4;
    printf("Countdown: ");
    while (countdown > 0) {
        if (countdown == 2) {
            countdown--;
            continue; // Skip printing 2
        }
        printf("%d ", countdown);
        countdown--;
    }
    printf("Liftoff!\\n");

    return 0;
}
```

## Expected Output
```text
Sum from 1 to 5: 15
Countdown: 4 3 1 Liftoff!
```

## Step-by-Step Code Explanation
- `for (int i = 1; i <= 5; i++)` sets `i = 1`, checks `i <= 5`, executes `total_sum += i`, and increments `i++` each cycle.
- In the `while` loop, when `countdown == 2`, `countdown` is decremented and `continue` skips the `printf` call.

## Common Mistakes
- **Off-by-one errors**: Using `<` instead of `<=` or starting at 0 instead of 1.
- **Infinite loops**: Forgetting to update loop control variables inside a `while` loop.
- **Trailing semicolon**: Writing `for (...);` causes the loop to run an empty statement repeatedly.

## Practice Exercise
Write a loop that prints the first 8 powers of 2 (1, 2, 4, 8, 16, 32, 64, 128).

## Estimated Completion Time
35 minutes
""",
    },
    {
        "order_number": 7,
        "title": "Functions and Modular Code",
        "content": """# Functions and Modular Code

## Summary
Functions break complex programs into small, self-contained, reusable modules. Each function performs a distinct task, accepts parameters, and optionally returns a computed result.

## Learning Objectives
- Write function prototypes (declarations) and definitions.
- Understand pass-by-value semantics in C.
- Manage local variable scope and return values.

## Syntax and Concepts
- Prototype: `return_type function_name(param_type param_name);`
- Definition:
  ```c
  return_type function_name(param_type param_name) {
      // body
      return value;
  }
  ```
- If a function returns nothing, use `void` as the return type.

## Runnable Code Example
```c
#include <stdio.h>

// Function prototype
int calculate_max(int x, int y);
void print_banner(void);

int main(void) {
    print_banner();
    int a = 45, b = 82;
    int highest = calculate_max(a, b);
    printf("Maximum between %d and %d is: %d\\n", a, b, highest);
    return 0;
}

// Function definitions
int calculate_max(int x, int y) {
    return (x > y) ? x : y;
}

void print_banner(void) {
    printf("===============================\\n");
    printf("   Kiko C Math Utilities       \\n");
    printf("===============================\\n");
}
```

## Expected Output
```text
===============================
   Kiko C Math Utilities       
===============================
Maximum between 45 and 82 is: 82
```

## Step-by-Step Code Explanation
- Prototypes at the top inform the compiler of function signatures before `main()` invokes them.
- `calculate_max(a, b)` passes copies of `a` and `b`. The function evaluates the ternary expression and returns the larger value.
- `print_banner()` returns `void`, so it performs output without returning a value.

## Common Mistakes
- **Calling before declaring**: Invoking a function before its declaration leads to implicit declaration compiler warnings or errors.
- **Expecting parameter changes**: Because C passes primitives by value, changing `x` inside `calculate_max` has no effect on `a` in `main()`.

## Practice Exercise
Write a function `double fahrenheit_to_celsius(double f)` that converts temperatures using `(f - 32.0) * 5.0 / 9.0`.

## Estimated Completion Time
30 minutes
""",
    },
    {
        "order_number": 8,
        "title": "Arrays and Strings",
        "content": """# Arrays and Strings

## Summary
Arrays store sequences of elements of the same type in contiguous memory blocks. In C, strings are simply one-dimensional character arrays terminated by a special null character (`'\\0'`).

## Learning Objectives
- Declare, initialize, and traverse one-dimensional arrays using index notation.
- Understand zero-based indexing and compute array lengths.
- Work with null-terminated character strings and standard `<string.h>` library functions.

## Syntax and Concepts
- Array: `int grades[5] = {85, 90, 78, 92, 88};`
- String: `char name[] = "Kiko";` (stored in memory as `'K'`, `'i'`, `'k'`, `'o'`, `'\\0'`).
- Size of array: `sizeof(arr) / sizeof(arr[0])`.

## Runnable Code Example
```c
#include <stdio.h>
#include <string.h>

int main(void) {
    int scores[] = {80, 95, 70, 85, 90};
    int count = sizeof(scores) / sizeof(scores[0]);
    int total = 0;

    for (int i = 0; i < count; i++) {
        total += scores[i];
    }
    double average = (double)total / count;
    printf("Scores Count: %d | Average: %.1f\\n", count, average);

    // String demonstration
    char platform_name[10] = "Kiko";
    printf("Platform: %s (Length: %lu bytes)\\n", platform_name, strlen(platform_name));

    return 0;
}
```

## Expected Output
```text
Scores Count: 5 | Average: 84.0
Platform: Kiko (Length: 4 bytes)
```

## Step-by-Step Code Explanation
- `scores[i]` accesses element `i` using contiguous memory offset.
- `sizeof(scores)` returns 20 bytes (5 integers * 4 bytes each), divided by `sizeof(scores[0])` (4 bytes) gives 5 elements.
- `strlen(platform_name)` counts characters up to (but not including) the terminating `'\\0'`.

## Common Mistakes
- **Index out of bounds**: Accessing `scores[5]` on an array of length 5 reads outside allocated memory (buffer overrun).
- **Missing null-terminator**: If a character array has no `'\\0'`, string functions like `printf("%s")` continue reading past the buffer until a random 0-byte is found in memory.

## Practice Exercise
Write a program that initializes an array of 6 integers, searches for a target value, and prints the index where it was found (or reports -1 if not found).

## Estimated Completion Time
35 minutes
""",
    },
    {
        "order_number": 9,
        "title": "Pointers and Memory Basics",
        "content": """# Pointers and Memory Basics

## Summary
Pointers are variables that store the memory address of another variable. They provide powerful memory manipulation capabilities, enabling dynamic memory allocation and pass-by-reference function behavior.

## Learning Objectives
- Use the address-of operator `&` to retrieve variable memory locations.
- Use the dereference operator `*` to read and write data through pointers.
- Implement pass-by-reference in functions to modify caller variables.

## Syntax and Concepts
- Pointer declaration: `int *ptr;` (pointer to an integer).
- Address assignment: `ptr = &target_var;`.
- Dereference: `*ptr = 100;` (modifies the value stored at `ptr`'s address).
- Null pointer: `int *ptr = NULL;` (points to no valid memory address).

## Runnable Code Example
```c
#include <stdio.h>

// Pass pointers to modify caller values
void swap_integers(int *x, int *y) {
    int temp = *x;
    *x = *y;
    *y = temp;
}

int main(void) {
    int first = 10, second = 20;

    printf("Before Swap: first = %d, second = %d\\n", first, second);
    swap_integers(&first, &second);
    printf("After Swap:  first = %d, second = %d\\n", first, second);

    return 0;
}
```

## Expected Output
```text
Before Swap: first = 10, second = 20
After Swap:  first = 20, second = 10
```

## Step-by-Step Code Explanation
- `&first` passes the memory address of `first` to parameter `x` (`int *x`).
- `int temp = *x;` dereferences `x` to read the value of `first` (10).
- `*x = *y;` dereferences `x` and writes the value of `second` directly into `first`'s memory.
- `*y = temp;` writes the stored value into `second`'s memory.

## Common Mistakes
- **Dereferencing NULL or uninitialized pointers**: `int *p; *p = 5;` attempts to write to a random memory address, causing immediate crashes.
- **Confusing pointer address with value**: `p` is the address; `*p` is the value stored at that address.

## Practice Exercise
Write a function `void square_number(int *n)` that replaces the integer pointed to by `n` with its square value.

## Estimated Completion Time
40 minutes
""",
    },
    {
        "order_number": 10,
        "title": "Structures and Introductory File Handling",
        "content": """# Structures and Introductory File Handling

## Summary
Structures (`struct`) group related variables of different data types into a single composite type. File handling enables long-term data persistence beyond program termination using standard file streams.

## Learning Objectives
- Define and instantiate custom `struct` types.
- Access struct members using the dot (`.`) and arrow (`->`) operators.
- Open, write, read, and close files safely using standard I/O streams (`fopen`, `fprintf`, `fclose`).

## Syntax and Concepts
- Struct definition:
  ```c
  struct Student {
      int id;
      char name[40];
      double gpa;
  };
  ```
- File stream: `FILE *fp = fopen("filename.txt", "w");`
- File closing: `fclose(fp);`

## Runnable Code Example
```c
#include <stdio.h>

struct Student {
    int id;
    char name[30];
    double gpa;
};

int main(void) {
    struct Student s1 = {101, "Alex Chen", 3.88};

    printf("Student Record:\\n");
    printf("ID:   %d\\n", s1.id);
    printf("Name: %s\\n", s1.name);
    printf("GPA:  %.2lf\\n", s1.gpa);

    // Demonstrate safe file operations
    FILE *fp = fopen("output.txt", "w");
    if (fp != NULL) {
        fprintf(fp, "%d,%s,%.2lf\\n", s1.id, s1.name, s1.gpa);
        fclose(fp);
        printf("Successfully wrote student record to output.txt\\n");
    }

    return 0;
}
```

## Expected Output
```text
Student Record:
ID:   101
Name: Alex Chen
GPA:  3.88
Successfully wrote student record to output.txt
```

## Step-by-Step Code Explanation
- `struct Student s1 = {101, "Alex Chen", 3.88};` initializes members in declaration order.
- `s1.name` accesses the member using the member access operator (`.`).
- `fopen("output.txt", "w")` opens the file in write mode. If the file cannot be created, `fopen` returns `NULL`.
- `fprintf(fp, ...)` writes formatted text into the file stream.
- `fclose(fp)` flushes buffered contents to disk and frees the operating system file handle.

## Common Mistakes
- **Forgetting `fclose()`**: Leaking open file handles can exhaust system resources and leave data unwritten in memory buffers.
- **Not checking for NULL**: Always verify `fp != NULL` before reading or writing to a file pointer.

## Practice Exercise
Define a `struct Rectangle` with `width` and `height` as doubles. Write a function that accepts a `struct Rectangle` and returns its calculated perimeter.

## Estimated Completion Time
40 minutes
""",
    },
]

C_EXAM_QUESTIONS = [
    {
        "order_number": 1,
        "question_text": "What is the mandatory entry point function where execution begins in every standard C program?",
        "options": ["start()", "main()", "run()", "init()"],
        "correct_option_index": 1,
        "explanation": "In standard C, program execution strictly begins at the main() function.",
    },
    {
        "order_number": 2,
        "question_text": "Which preprocessor directive is required to use standard I/O functions like printf() and scanf() in C?",
        "options": ["#include <stdlib.h>", "#include <string.h>", "#include <stdio.h>", "#include <math.h>"],
        "correct_option_index": 2,
        "explanation": "<stdio.h> (Standard Input/Output) contains the declarations for printf() and scanf().",
    },
    {
        "order_number": 3,
        "question_text": "Which format specifier is used with printf() to display a double-precision floating-point number?",
        "options": ["%d", "%f", "%lf", "%c"],
        "correct_option_index": 2,
        "explanation": "%lf is the format specifier for double in printf and scanf, while %f is for single-precision float.",
    },
    {
        "order_number": 4,
        "question_text": "What keyword in C is used to declare a variable whose value cannot be modified after initialization?",
        "options": ["constant", "final", "const", "static"],
        "correct_option_index": 2,
        "explanation": "The const keyword makes a variable read-only, preventing subsequent assignment.",
    },
    {
        "order_number": 5,
        "question_text": "When reading an integer into `int age;` using `scanf(\"%d\", &age);`, why is the `&` operator required?",
        "options": [
            "To convert age to a pointer type",
            "To pass the memory address of age so scanf can write the input value directly into it",
            "To calculate the byte size of age",
            "To verify that age is positive"
        ],
        "correct_option_index": 1,
        "explanation": "C passes arguments by value. Passing &age provides the memory address so scanf can modify the caller's variable directly.",
    },
    {
        "order_number": 6,
        "question_text": "What is the result of the integer division `7 / 2` in C?",
        "options": ["3.5", "3", "4", "3.0"],
        "correct_option_index": 1,
        "explanation": "In C, dividing two integers performs integer division, which truncates any decimal part toward zero, giving 3.",
    },
    {
        "order_number": 7,
        "question_text": "What is the result of the modulus expression `17 % 5` in C?",
        "options": ["3", "2", "3.4", "1"],
        "correct_option_index": 1,
        "explanation": "The modulus operator (%) computes the integer remainder after division: 17 divided by 5 is 3 with remainder 2.",
    },
    {
        "order_number": 8,
        "question_text": "What will happen in C when evaluating `if (x = 5)` if `int x = 0;` initially?",
        "options": [
            "A compilation syntax error is raised",
            "It evaluates to false because x was 0",
            "It assigns 5 to x and evaluates to true because 5 is non-zero",
            "It compares x to 5 and yields false"
        ],
        "correct_option_index": 2,
        "explanation": "A single equals sign = is the assignment operator. `x = 5` stores 5 into x and produces 5, which evaluates to true (non-zero). Equality check requires ==.",
    },
    {
        "order_number": 9,
        "question_text": "What happens in a C switch statement if a matching case block omits a `break` statement?",
        "options": [
            "The program immediately terminates",
            "Execution falls through and continues into subsequent cases until a break or the end of switch is reached",
            "A runtime exception is thrown",
            "The default case executes next regardless of its position"
        ],
        "correct_option_index": 1,
        "explanation": "In C, switch cases fall through by default unless terminated with a break statement.",
    },
    {
        "order_number": 10,
        "question_text": "Given `int score = 85; char *res = (score >= 70) ? \"Pass\" : \"Fail\";`, what value is stored in `res`?",
        "options": ["Fail", "Pass", "NULL", "85"],
        "correct_option_index": 1,
        "explanation": "The ternary operator evaluates `score >= 70`. Since 85 >= 70 is true, it yields \"Pass\".",
    },
    {
        "order_number": 11,
        "question_text": "How many times does this loop execute? `for (int i = 0; i < 5; i++)`",
        "options": ["4 times", "5 times", "6 times", "Infinite"],
        "correct_option_index": 1,
        "explanation": "The loop executes for i = 0, 1, 2, 3, 4, which is exactly 5 iterations.",
    },
    {
        "order_number": 12,
        "question_text": "How does a `do-while` loop differ fundamentally from a standard `while` loop in C?",
        "options": [
            "A do-while loop never terminates",
            "A do-while loop always executes its body at least once before testing the condition",
            "A do-while loop tests the condition before the first iteration",
            "A do-while loop only works with integer conditions"
        ],
        "correct_option_index": 1,
        "explanation": "In a do-while loop, the condition is evaluated at the bottom, guaranteeing that the body executes at least once.",
    },
    {
        "order_number": 13,
        "question_text": "Why are function prototypes placed before `main()` or in header files?",
        "options": [
            "To allocate stack memory for the function",
            "To inform the compiler of the function's name, return type, and parameters before its call is encountered",
            "To execute the function during compilation",
            "To prevent the function from returning values"
        ],
        "correct_option_index": 1,
        "explanation": "Prototypes provide forward declarations so the compiler can validate arguments and return types before encountering function bodies.",
    },
    {
        "order_number": 14,
        "question_text": "By default, how are primitive arguments passed to functions in C?",
        "options": ["Pass by reference", "Pass by value", "Pass by pointer", "Pass by name"],
        "correct_option_index": 1,
        "explanation": "C is strictly a pass-by-value language. A copy of the argument value is passed to the function parameter.",
    },
    {
        "order_number": 15,
        "question_text": "Given `int numbers[5] = {10, 20, 30, 40, 50};`, what are the values of `numbers[0]` and `numbers[4]`?",
        "options": ["10 and 40", "10 and 50", "0 and 4", "Garbage values"],
        "correct_option_index": 1,
        "explanation": "C arrays use 0-based indexing. Index 0 is the first element (10), and index 4 is the fifth element (50).",
    },
    {
        "order_number": 16,
        "question_text": "In C, what special character marks the end of a character string in memory?",
        "options": ["'\\n'", "'\\t'", "'\\0'", "EOF"],
        "correct_option_index": 2,
        "explanation": "Strings in C are null-terminated character arrays. The null byte ('\\0' with ASCII value 0) marks the end of the string.",
    },
    {
        "order_number": 17,
        "question_text": "Given `int x = 42; int *p = &x;`, what does the expression `*p` evaluate to?",
        "options": ["The memory address of x", "The value 42", "The memory address of pointer p", "An uninitialized pointer"],
        "correct_option_index": 1,
        "explanation": "Applying the dereference operator * to pointer p accesses the value stored at the address pointed to, which is 42.",
    },
    {
        "order_number": 18,
        "question_text": "Which function prototype allows swapping the values of two integers in the caller's scope?",
        "options": [
            "void swap(int a, int b);",
            "void swap(int *a, int *b);",
            "int swap(int &a, int &b);",
            "void swap(int a[], int b);"
        ],
        "correct_option_index": 1,
        "explanation": "To modify caller variables in C, memory addresses must be passed as pointers (`int *a, int *b`).",
    },
    {
        "order_number": 19,
        "question_text": "Given `struct Point { int x; int y; }; struct Point p1 = {3, 7};`, how do you access member `x`?",
        "options": ["p1->x", "p1.x", "p1::x", "p1[0]"],
        "correct_option_index": 1,
        "explanation": "The direct member access operator (.) is used with struct instances. The arrow operator (->) is used when accessing through a pointer.",
    },
    {
        "order_number": 20,
        "question_text": "Why must `fclose()` be called on every file opened with `fopen()`?",
        "options": [
            "To delete the file from disk",
            "To flush unwritten buffered data to storage and release system file descriptors",
            "To encrypt the file contents",
            "It is optional and does not affect the system"
        ],
        "correct_option_index": 1,
        "explanation": "Calling fclose() writes any buffered data to disk and frees the operating system file descriptor to prevent resource leaks.",
    },
]

PYTHON_COURSE_METADATA = {
    "title": "Python Fundamentals for Beginners",
    "description": "Learn clean, readable programming concepts with Python, including variables, collections, loops, functions, dictionaries, and exception handling.",
    "language": "Python",
    "is_published": True,
}

PYTHON_LESSONS = [
    {
        "order_number": 1,
        "title": "Introduction to Python and Running Programs",
        "content": """# Introduction to Python and Running Programs

## Summary
Python is an interpreted, high-level, dynamically typed programming language known for its clean syntax and human readability. Created by Guido van Rossum in 1991, Python emphasizes developer productivity and simplicity.

## Learning Objectives
- Understand how the Python interpreter executes code line by line.
- Write single-line comments and output text using the `print()` function.
- Understand how whitespace indentation defines code structure.

## Syntax and Concepts
- Comments start with `#` and are ignored by the interpreter.
- Statements are executed sequentially without requiring trailing semicolons.
- Output text is produced using `print(...)`.

## Runnable Code Example
```python
# First Python program
def welcome_student(name):
    # Indentation defines the block
    greeting = f"Welcome to Kiko, {name}!"
    return greeting

message = welcome_student("Learner")
print(message)
print("Python is clean, readable, and powerful.")
```

## Expected Output
```text
Welcome to Kiko, Learner!
Python is clean, readable, and powerful.
```

## Step-by-Step Code Explanation
- `# First Python program` is a comment explaining the code.
- `def welcome_student(name):` defines a function. Notice the colon (`:`) at the end of the line.
- The 4-space indented block inside the function belongs to that function's scope.
- `print(...)` displays the string on the standard output stream.

## Common Mistakes
- **IndentationError**: Mixing tabs and spaces or using inconsistent indentation levels.
- **Missing closing quotes**: Forgetting to match single or double quotes causes a `SyntaxError`.

## Practice Exercise
Write a Python script that defines a variable with your favorite hobby and prints: `"My favorite hobby is: <hobby>"`.

## Estimated Completion Time
20 minutes
""",
    },
    {
        "order_number": 2,
        "title": "Variables, Fundamental Data Types, and Type Conversion",
        "content": """# Variables, Fundamental Data Types, and Type Conversion

## Summary
Python variables are dynamically typed references to objects in memory. You do not declare variable types explicitly; Python infers the type at runtime based on the assigned value.

## Learning Objectives
- Identify fundamental types: `int`, `float`, `str`, and `bool`.
- Check object types using the `type()` built-in function.
- Convert between types using `int()`, `float()`, and `str()`.

## Syntax and Concepts
- `int`: Whole numbers (e.g., `42`, `-10`).
- `float`: Real numbers with decimal points (e.g., `3.14`).
- `str`: Text enclosed in single or double quotes (e.g., `'Python'`).
- `bool`: Truth values (`True` or `False`).
- Casting: `int("100")` turns a string into an integer.

## Runnable Code Example
```python
student_age = 21
gpa = 3.85
is_enrolled = True
student_name = "Alex Chen"

print("Age:", student_age, "| Type:", type(student_age).__name__)
print("GPA:", gpa, "| Type:", type(gpa).__name__)
print("Enrolled:", is_enrolled, "| Type:", type(is_enrolled).__name__)

# Type casting demonstration
input_str = "150"
total_credits = int(input_str) + 10
print(f"Total credits after casting: {total_credits}")
```

## Expected Output
```text
Age: 21 | Type: int
GPA: 3.85 | Type: float
Enrolled: True | Type: bool
Total credits after casting: 160
```

## Step-by-Step Code Explanation
- `student_age = 21` creates an integer object and binds the name `student_age` to it.
- `type(student_age)` returns `<class 'int'>`.
- `int(input_str)` parses the string `"150"` into the integer `150`, enabling arithmetic addition with `10`.

## Common Mistakes
- **TypeError during concatenation**: Attempting `"Age: " + 21` raises a `TypeError`. Use `f"Age: {student_age}"` or `"Age: " + str(student_age)`.
- **Invalid cast values**: `int("abc")` raises a `ValueError` because `"abc"` cannot be parsed as a base-10 integer.

## Practice Exercise
Declare two string variables `"45"` and `"55"`, cast them to integers, add them together, and print their sum.

## Estimated Completion Time
25 minutes
""",
    },
    {
        "order_number": 3,
        "title": "Input and Output Operations",
        "content": """# Input and Output Operations

## Summary
Interactive programs receive user input through the `input()` function and format responses cleanly using modern f-strings (formatted string literals).

## Learning Objectives
- Read keyboard input with `input()`.
- Format dynamic strings with f-strings (`f"{var}"`).
- Format numbers with precision specifiers (e.g., `f"{val:.2f}"`).

## Syntax and Concepts
- `input(prompt)`: Displays prompt and waits for user input. Always returns a `str`.
- f-strings: `f"Hello, {name}!"` evaluates expressions inside `{}` at runtime.
- Specifier `:.2f`: Formats floating-point numbers to two decimal places.

## Runnable Code Example
```python
# Simulating input parsing
raw_item_name = "Programming Textbook"
raw_price = "59.99"
raw_tax_rate = "0.08"

item_price = float(raw_price)
tax_amount = item_price * float(raw_tax_rate)
total_cost = item_price + tax_amount

print("Receipt Summary:")
print(f"Item:       {raw_item_name}")
print(f"Base Price: ${item_price:.2f}")
print(f"Tax:        ${tax_amount:.2f}")
print(f"Total Due:  ${total_cost:.2f}")
```

## Expected Output
```text
Receipt Summary:
Item:       Programming Textbook
Base Price: $59.99
Tax:        $4.80
Total Due:  $64.79
```

## Step-by-Step Code Explanation
- `float(raw_price)` casts the string representation to a floating-point number.
- `f"Total Due: ${total_cost:.2f}"` rounds the computed float to two decimal places for currency presentation.

## Common Mistakes
- **Forgetting input is always a string**: `val = input(); result = val * 2` repeats the string twice (`"5" * 2 == "55"`) instead of doubling the number.

## Practice Exercise
Write a snippet that prompts for a temperature in Celsius, converts it to Fahrenheit using `f = (c * 9/5) + 32`, and prints the result rounded to 1 decimal place.

## Estimated Completion Time
25 minutes
""",
    },
    {
        "order_number": 4,
        "title": "Operators and Expressions",
        "content": """# Operators and Expressions

## Summary
Operators perform computations on variables and values. Python provides arithmetic operators including integer floor division (`//`) and exponentiation (`**`), comparison operators, and readable logical operators (`and`, `or`, `not`).

## Learning Objectives
- Differentiate between float division (`/`) and integer floor division (`//`).
- Compute powers using exponentiation (`**`).
- Evaluate compound expressions using boolean operators `and`, `or`, and `not`.

## Syntax and Concepts
- `a / b`: Always returns a `float` in Python 3.
- `a // b`: Floor division; returns integer rounded toward negative infinity.
- `a ** b`: Exponentiation (e.g. `2 ** 3 == 8`).
- `a % b`: Modulus remainder.
- `and`, `or`, `not`: Word-based logical operators with short-circuit evaluation.

## Runnable Code Example
```python
a = 15
b = 4

print("True Division 15 / 4: ", a / b)
print("Floor Division 15 // 4:", a // b)
print("Remainder 15 % 4:     ", a % b)
print("Power 2 ** 4:         ", 2 ** 4)

is_in_range = (a > 10) and (b < 10)
print(f"Is a > 10 and b < 10?  {is_in_range}")
```

## Expected Output
```text
True Division 15 / 4:  3.75
Floor Division 15 // 4: 3
Remainder 15 % 4:      3
Power 2 ** 4:          16
Is a > 10 and b < 10?  True
```

## Step-by-Step Code Explanation
- `15 / 4` evaluates to `3.75` (float).
- `15 // 4` drops the fractional part and returns `3` (int).
- `2 ** 4` evaluates to `16` (2 * 2 * 2 * 2).
- `and` requires both operands to be true, producing `True`.

## Common Mistakes
- **Using `^` for exponents**: In Python, `^` is bitwise XOR, not exponentiation. Use `**` for powers.
- **Using `&` instead of `and`**: `&` is a bitwise AND operator, not logical boolean AND.

## Practice Exercise
Write an expression that evaluates to `True` if a variable `n` is between 20 and 50 inclusive and is also an even number.

## Estimated Completion Time
25 minutes
""",
    },
    {
        "order_number": 5,
        "title": "Conditional Statements: If, Elif, and Else",
        "content": """# Conditional Statements: If, Elif, and Else

## Summary
Conditional logic directs program execution down different paths based on boolean evaluations. Python uses `if`, `elif`, and `else` blocks organized by whitespace indentation.

## Learning Objectives
- Construct multi-branch decision structures with `if`, `elif`, and `else`.
- Understand truthy and falsy values in Python.
- Use ternary conditional expressions (`a if cond else b`).

## Syntax and Concepts
- Structure:
  ```python
  if condition_1:
      # runs when condition_1 is True
  elif condition_2:
      # runs when condition_1 is False and condition_2 is True
  else:
      # runs when all previous conditions are False
  ```
- Falsy values: `0`, `0.0`, `""`, `[]`, `{}`, `set()`, `None`, and `False`. Everything else is truthy.

## Runnable Code Example
```python
score = 84

if score >= 90:
    grade = "A"
    feedback = "Exceptional achievement!"
elif score >= 80:
    grade = "B"
    feedback = "Solid performance. Well done!"
elif score >= 70:
    grade = "C"
    feedback = "Passing grade. Review challenging topics."
else:
    grade = "F"
    feedback = "Retake the assessment after study."

print(f"Grade: {grade} | Feedback: {feedback}")

# Ternary expression
status = "Passed" if score >= 70 else "Failed"
print(f"Course Status: {status}")
```

## Expected Output
```text
Grade: B | Feedback: Solid performance. Well done!
Course Status: Passed
```

## Step-by-Step Code Explanation
- Python tests `score >= 90` (False), then evaluates `score >= 80` (True).
- It executes the `elif score >= 80:` block and skips all subsequent `elif` and `else` branches.
- `status = "Passed" if score >= 70 else "Failed"` cleanly assigns a value in a single line.

## Common Mistakes
- **Missing colon (`:`)**: Every `if`, `elif`, and `else` line must end with a colon.
- **Using `else if`**: Python uses `elif`, not `else if`.

## Practice Exercise
Write a conditional statement that checks if a string variable `username` is empty, and if so, sets it to `"guest"`.

## Estimated Completion Time
30 minutes
""",
    },
    {
        "order_number": 6,
        "title": "Loops and Iteration",
        "content": """# Loops and Iteration

## Summary
Loops repeat actions over collections or numeric ranges. Python offers `for` loops that iterate over sequences directly, and `while` loops that continue as long as a condition holds true.

## Learning Objectives
- Use `for` loops with the built-in `range()` function.
- Iterate directly over lists and string characters.
- Use `break` and `continue` to manage loop execution.

## Syntax and Concepts
- `range(stop)`: Generates numbers from `0` to `stop - 1`.
- `range(start, stop, step)`: Starts at `start`, stops before `stop`, incrementing by `step`.
- `while condition:`: Loops while `condition` remains true.
- `break`: Aborts the loop immediately.
- `continue`: Skips to the next cycle.

## Runnable Code Example
```python
# Sum numbers 1 through 5 using range
total_sum = 0
for num in range(1, 6):
    total_sum += num
print(f"Sum of 1 through 5: {total_sum}")

# Iterate through a list with continue
technologies = ["Python", "C", "HTML", "Docker", "Git"]
print("Filtered list (skipping short names):")
for tech in technologies:
    if len(tech) <= 2:
        continue  # skip names with length <= 2
    print(f"- {tech}")
```

## Expected Output
```text
Sum of 1 through 5: 15
Filtered list (skipping short names):
- Python
- HTML
- Docker
- Git
```

## Step-by-Step Code Explanation
- `range(1, 6)` generates `1, 2, 3, 4, 5`. The stop value `6` is exclusive.
- `for tech in technologies:` extracts each item sequentially.
- When `tech == "C"`, `len("C") <= 2` is True, so `continue` skips the print call and moves to `"HTML"`.

## Common Mistakes
- **Exclusive stop**: Forgetting that `range(1, 5)` generates numbers up to 4, not 5.
- **Modifying while iterating**: Removing elements from a list while looping over it causes skipped items.

## Practice Exercise
Write a loop that prints the square of every even number from 2 through 10.

## Estimated Completion Time
30 minutes
""",
    },
    {
        "order_number": 7,
        "title": "Strings and Sequence Operations",
        "content": """# Strings and Sequence Operations

## Summary
Strings in Python are immutable sequences of Unicode characters. Python provides powerful sequence indexing, slicing syntax (`[start:stop:step]`), and rich built-in string methods.

## Learning Objectives
- Access characters using positive and negative indices.
- Slice strings using `[start:stop:step]` notation.
- Apply essential string methods: `.upper()`, `.lower()`, `.strip()`, `.split()`, and `.join()`.

## Syntax and Concepts
- Negative index `-1` references the last character.
- Slicing `text[0:4]` extracts characters from index 0 to 3.
- Slicing `text[::-1]` reverses a string.
- Strings are immutable: methods return a new modified string rather than altering the original.

## Runnable Code Example
```python
course_title = "  learn python programming with kiko  "

# Strip whitespace and capitalize words
clean_title = course_title.strip().title()
print("Clean Title:", clean_title)

# Slicing
first_word = clean_title[:5]
print("First Word:", first_word)

# Reversing via slice step
code_name = "KIKO"
reversed_name = code_name[::-1]
print(f"Reversed '{code_name}': {reversed_name}")

# Split and Join
tags = "c,python,fastapi,flutter"
tag_list = tags.split(",")
formatted_tags = " | ".join(tag_list)
print("Tags:", formatted_tags)
```

## Expected Output
```text
Clean Title: Learn Python Programming With Kiko
First Word: Learn
Reversed 'KIKO': OKIK
Tags: c | python | fastapi | flutter
```

## Step-by-Step Code Explanation
- `course_title.strip()` removes leading and trailing spaces; `.title()` capitalizes each word.
- `clean_title[:5]` extracts indices 0, 1, 2, 3, 4.
- `tags.split(",")` breaks the string into a list `['c', 'python', 'fastapi', 'flutter']`.
- `" | ".join(...)` merges the list back into a single string with separators.

## Common Mistakes
- **Attempting string mutation**: `s = "hello"; s[0] = "H"` raises a `TypeError`. Create a new string with `"H" + s[1:]`.
- **Off-by-one in slices**: The stop index is non-inclusive.

## Practice Exercise
Write a function `is_palindrome(word)` that returns `True` if `word.lower()` is equal to its reversed slice.

## Estimated Completion Time
35 minutes
""",
    },
    {
        "order_number": 8,
        "title": "Functions, Parameters, and Scope",
        "content": """# Functions, Parameters, and Scope

## Summary
Functions are reusable code blocks defined with the `def` keyword. They can accept positional arguments, keyword arguments, and default parameters, and return single or multiple values via tuples.

## Learning Objectives
- Define and invoke functions using `def` and `return`.
- Use default parameter values effectively.
- Understand local versus global variable scope.

## Syntax and Concepts
- Definition:
  ```python
  def calculate_stats(scores, scale=100):
      average = sum(scores) / len(scores)
      return average, len(scores)  # returns a tuple
  ```
- Variables created inside a function are local to that function.

## Runnable Code Example
```python
def calculate_rectangle_area(width, height=10):
    # Compute the area of a rectangle with optional default height.
    return width * height

# Calling with both arguments
area1 = calculate_rectangle_area(5, 20)
# Calling using the default height of 10
area2 = calculate_rectangle_area(7)

print(f"Area 1 (5 x 20): {area1}")
print(f"Area 2 (7 x 10): {area2}")

def min_and_max(numbers):
    return min(numbers), max(numbers)

lowest, highest = min_and_max([12, 45, 7, 89, 23])
print(f"Lowest: {lowest}, Highest: {highest}")
```

## Expected Output
```text
Area 1 (5 x 20): 100
Area 2 (7 x 10): 70
Lowest: 7, Highest: 89
```

## Step-by-Step Code Explanation
- `height=10` provides a fallback value if the caller omits the second argument.
- `min_and_max(...)` returns a tuple `(7, 89)`, which is unpacked cleanly into variables `lowest` and `highest`.

## Common Mistakes
- **Mutable default arguments**: Defining `def append_to(item, target=[])` shares the same list across calls. Use `target=None` and initialize inside the function.
- **Forgetting `return`**: Functions without an explicit `return` statement return `None` by default.

## Practice Exercise
Write a function `format_full_name(first, last, title="")` that returns `f"{title} {first} {last}".strip()`.

## Estimated Completion Time
35 minutes
""",
    },
    {
        "order_number": 9,
        "title": "Dictionaries and Sets",
        "content": """# Dictionaries and Sets

## Summary
Dictionaries (`dict`) store key-value mappings with fast O(1) average lookup. Sets (`set`) store unordered, unique elements and provide mathematical set operations like union and intersection.

## Learning Objectives
- Create, update, and traverse dictionaries.
- Retrieve dictionary values safely with `.get()` to avoid `KeyError`.
- Use sets to remove duplicates and compute intersections and unions.

## Syntax and Concepts
- Dictionary: `student = {"name": "Alex", "age": 21, "gpa": 3.8}`
- Safe lookup: `student.get("major", "Undeclared")` returns fallback if key is missing.
- Set: `unique_ids = {101, 102, 103}`
- Set operations: `s1 & s2` (intersection), `s1 | s2` (union).

## Runnable Code Example
```python
# Dictionary demonstration
course = {
    "title": "Python Fundamentals",
    "language": "Python",
    "lesson_count": 10,
    "is_published": True
}

print(f"Course: {course['title']}")
# Safe access with .get()
certificate = course.get("certificate", "Not Included")
print(f"Certificate: {certificate}")

# Set demonstration: removing duplicates
enrolled_ids = [101, 102, 105, 101, 108, 102]
unique_students = set(enrolled_ids)
print("Unique Students Count:", len(unique_students))

group_a = {"Python", "C", "SQL"}
group_b = {"Python", "Rust", "Go"}
common_skills = group_a & group_b
print("Common Skills:", common_skills)
```

## Expected Output
```text
Course: Python Fundamentals
Certificate: Not Included
Unique Students Count: 4
Common Skills: {'Python'}
```

## Step-by-Step Code Explanation
- `course["title"]` retrieves the value associated with key `"title"`.
- `course.get("certificate", ...)` safely yields `"Not Included"` because the key doesn't exist.
- `set(enrolled_ids)` eliminates duplicate IDs `101` and `102`.
- `group_a & group_b` finds common elements present in both sets (`{'Python'}`).

## Common Mistakes
- **KeyError**: Accessing `course["missing_key"]` directly raises a `KeyError`. Use `.get()` or check `if "missing_key" in course:`.
- **Un-hashable dictionary keys**: Lists cannot be used as dictionary keys because they are mutable.

## Practice Exercise
Write a function that accepts a sentence string and returns a dictionary counting the occurrence of each word.

## Estimated Completion Time
35 minutes
""",
    },
    {
        "order_number": 10,
        "title": "Exceptions and File Handling",
        "content": """# Exceptions and File Handling

## Summary
Defensive programs anticipate runtime errors using `try`, `except`, `else`, and `finally` blocks. File handling allows persisting data to storage using the `with open(...)` context manager, which guarantees file closure.

## Learning Objectives
- Handle runtime errors with `try` and `except` without crashing.
- Catch specific exceptions like `ValueError`, `ZeroDivisionError`, and `FileNotFoundError`.
- Open, read, and write files safely with the `with` statement.

## Syntax and Concepts
- Exception structure:
  ```python
  try:
      # risky code
  except ValueError as e:
      # handle specific error
  finally:
      # always runs
  ```
- File context manager: `with open("file.txt", "w") as f: f.write("...")`

## Runnable Code Example
```python
def safe_divide(numerator, denominator):
    try:
        result = numerator / denominator
    except ZeroDivisionError:
        return "Error: Cannot divide by zero."
    except TypeError:
        return "Error: Numeric inputs required."
    else:
        return f"Result: {result:.2f}"
    finally:
        pass  # cleanup hook

print(safe_divide(20, 4))
print(safe_divide(15, 0))

# Safe file writing and reading demonstration
filename = "kiko_log.txt"
with open(filename, "w") as file:
    file.write("Kiko Learning Log\\nLesson 10 Complete\\n")

with open(filename, "r") as file:
    lines = file.readlines()
    print("Read from file:", [line.strip() for line in lines])
```

## Expected Output
```text
Result: 5.00
Error: Cannot divide by zero.
Read from file: ['Kiko Learning Log', 'Lesson 10 Complete']
```

## Step-by-Step Code Explanation
- `safe_divide(15, 0)` raises `ZeroDivisionError`, which is intercepted by the matching `except` block.
- The `with open(...)` statement automatically calls `file.close()` when exiting the block, even if an exception occurs.
- `readlines()` reads all lines from the file stream into a list.

## Common Mistakes
- **Bare `except:`**: Catching all exceptions with a bare `except:` can hide syntax errors and prevent keyboard interrupts. Always specify exception types (`except ValueError:`).
- **Manual file closing**: Calling `open()` without `with` risks leaving files open if an error occurs before `.close()`.

## Practice Exercise
Write a function that asks for a file name, attempts to open and read its text, and returns `"File not found"` if a `FileNotFoundError` occurs.

## Estimated Completion Time
40 minutes
""",
    },
]

PYTHON_EXAM_QUESTIONS = [
    {
        "order_number": 1,
        "question_text": "How does Python define code blocks for functions, loops, and conditional statements?",
        "options": ["Curly braces {}", "Whitespace indentation", "Keywords begin and end", "Parentheses ()"],
        "correct_option_index": 1,
        "explanation": "Unlike C or Java, Python uses uniform whitespace indentation (typically 4 spaces) to delimit code blocks.",
    },
    {
        "order_number": 2,
        "question_text": "Which symbol is used to start a single-line comment in Python?",
        "options": ["//", "/*", "#", "--"],
        "correct_option_index": 2,
        "explanation": "The # symbol begins a single-line comment in Python that is ignored by the interpreter.",
    },
    {
        "order_number": 3,
        "question_text": "What is the return value of `type(3.14)` in Python?",
        "options": ["<class 'int'>", "<class 'float'>", "<class 'double'>", "<class 'decimal'>"],
        "correct_option_index": 1,
        "explanation": "In Python, floating-point numbers with decimal points belong to the built-in `float` class.",
    },
    {
        "order_number": 4,
        "question_text": "What is the result of evaluating `int(\"100\") + 20` in Python?",
        "options": ["'10020'", "120", "TypeError", "100.20"],
        "correct_option_index": 1,
        "explanation": "`int(\"100\")` parses the string to integer 100, which is then added to 20, resulting in 120.",
    },
    {
        "order_number": 5,
        "question_text": "What data type does the built-in `input()` function always return?",
        "options": ["int", "float", "str", "Depends on user input"],
        "correct_option_index": 2,
        "explanation": "In Python 3, `input()` always returns user input as a string (`str`). Numeric inputs must be explicitly cast.",
    },
    {
        "order_number": 6,
        "question_text": "What is the output of `name = 'Kiko'; f'Hello, {name.upper()}!'`?",
        "options": ["'Hello, name!'", "'Hello, Kiko!'", "'Hello, KIKO!'", "SyntaxError"],
        "correct_option_index": 2,
        "explanation": "f-strings evaluate expressions inside {} at runtime, so `name.upper()` produces 'KIKO'.",
    },
    {
        "order_number": 7,
        "question_text": "What is the result of `7 // 2` versus `7 / 2` in Python 3?",
        "options": ["3 and 3.5", "3.5 and 3", "3 and 3", "3.5 and 3.5"],
        "correct_option_index": 0,
        "explanation": "`//` is floor division (returns integer 3) while `/` is float division (returns 3.5).",
    },
    {
        "order_number": 8,
        "question_text": "Which operator is used to calculate powers (exponentiation) in Python, such as 2 to the power 3?",
        "options": ["2 ^ 3", "2 ** 3", "2 && 3", "pow_operator(2, 3)"],
        "correct_option_index": 1,
        "explanation": "The `**` operator performs exponentiation in Python (`2 ** 3 == 8`). `^` is bitwise XOR.",
    },
    {
        "order_number": 9,
        "question_text": "Which keyword is used in Python for chained conditional branching (\"else if\")?",
        "options": ["else if", "elseif", "elif", "case"],
        "correct_option_index": 2,
        "explanation": "Python uses `elif` as the keyword for additional conditional branches between `if` and `else`.",
    },
    {
        "order_number": 10,
        "question_text": "Which of the following values is considered truthy (evaluates to True) in a Python boolean context?",
        "options": ["[]", "0", "''", "[-1]"],
        "correct_option_index": 3,
        "explanation": "Empty collections `[]`, `''`, and zero `0` are falsy in Python. Non-empty lists like `[-1]` are truthy.",
    },
    {
        "order_number": 11,
        "question_text": "What sequence of integers is generated by `list(range(1, 6))`?",
        "options": ["[1, 2, 3, 4, 5, 6]", "[1, 2, 3, 4, 5]", "[0, 1, 2, 3, 4, 5]", "[2, 3, 4, 5]"],
        "correct_option_index": 1,
        "explanation": "`range(1, 6)` starts at 1 and stops before 6 (stop value is exclusive), yielding [1, 2, 3, 4, 5].",
    },
    {
        "order_number": 12,
        "question_text": "Which statement immediately skips the rest of the current iteration and advances to the next loop iteration?",
        "options": ["break", "continue", "pass", "skip"],
        "correct_option_index": 1,
        "explanation": "`continue` terminates the current iteration and jumps directly to the next loop cycle, whereas `break` exits the loop entirely.",
    },
    {
        "order_number": 13,
        "question_text": "What happens when executing `text = 'hello'; text[0] = 'H'` in Python?",
        "options": [
            "text becomes 'Hello'",
            "A TypeError is raised because strings are immutable",
            "text becomes 'Hhello'",
            "text is unchanged without error"
        ],
        "correct_option_index": 1,
        "explanation": "Strings in Python are immutable; individual characters cannot be reassigned in-place.",
    },
    {
        "order_number": 14,
        "question_text": "Given `letters = ['a', 'b', 'c', 'd', 'e']`, what does the slice `letters[1:4]` produce?",
        "options": ["['a', 'b', 'c']", "['b', 'c', 'd']", "['b', 'c', 'd', 'e']", "['c', 'd', 'e']"],
        "correct_option_index": 1,
        "explanation": "Slice `[1:4]` starts at index 1 ('b') and includes elements up to index 3 ('d') before stopping at 4.",
    },
    {
        "order_number": 15,
        "question_text": "Which keyword is used to define a function in Python?",
        "options": ["function", "fun", "def", "define"],
        "correct_option_index": 2,
        "explanation": "Functions in Python are declared with the `def` keyword followed by the function name and parameters.",
    },
    {
        "order_number": 16,
        "question_text": "Given `def greet(name, greeting=\"Hello\"): return f\"{greeting}, {name}\"`, what does `greet(\"Alex\")` return?",
        "options": ["'Hello, Alex'", "'Alex, Hello'", "TypeError: missing argument", "'None, Alex'"],
        "correct_option_index": 0,
        "explanation": "When the optional parameter `greeting` is omitted in the call, its default value `\"Hello\"` is used.",
    },
    {
        "order_number": 17,
        "question_text": "What is the recommended way to retrieve a key from a dictionary `user` without risking a `KeyError` if the key is missing?",
        "options": ["user[key]", "user.get(key, default)", "user.find(key)", "user.lookup(key)"],
        "correct_option_index": 1,
        "explanation": "`dict.get(key, default)` safely returns the value or a fallback default instead of raising a KeyError.",
    },
    {
        "order_number": 18,
        "question_text": "What is the output of `len(set([1, 2, 2, 3, 3, 3, 4]))` in Python?",
        "options": ["7", "4", "3", "1"],
        "correct_option_index": 1,
        "explanation": "A set stores only unique elements. Converting `[1, 2, 2, 3, 3, 3, 4]` to a set yields `{1, 2, 3, 4}`, with length 4.",
    },
    {
        "order_number": 19,
        "question_text": "Why is the `with open('data.txt', 'r') as file:` construct preferred over `file = open('data.txt')`?",
        "options": [
            "It makes file reading execute in parallel",
            "It automatically closes the file even if an exception occurs inside the block",
            "It encrypts the file on disk",
            "It allows multiple processes to write to the file simultaneously"
        ],
        "correct_option_index": 1,
        "explanation": "The `with` statement leverages context managers, guaranteeing that `file.close()` is invoked upon exit.",
    },
    {
        "order_number": 20,
        "question_text": "Which block in a `try-except-finally` statement always executes, regardless of whether an exception occurred?",
        "options": ["try", "except", "else", "finally"],
        "correct_option_index": 3,
        "explanation": "Code inside the `finally` block is guaranteed to run after try/except blocks complete, even if unhandled exceptions occur.",
    },
]
