SHELL:= /bin/bash
all:
	@echo 'Use "make venv" for installing dependencies, "make input" for test data generation or "make run" for profiling.'
.PHONY: all


venv:
	rm -rf venv
	python3 -m venv venv
	./venv/bin/pip install poetry
	./venv/bin/poetry install --no-root
.PHONY: venv


input:
	@echo "Creating dummy text file from random text"
	@./venv/bin/poetry run python3 lorem_text_gen.py --sentences=10000 --field-length-min 3 --field-length-max 3 > input_fix.txt
	@./venv/bin/poetry run python3 lorem_text_gen.py --sentences=10000 --field-length-min 1 --field-length-max 5 > input_var.txt
	@cat input_fix.txt | head -n1000 > input_fix_1000.txt
	@cat input_var.txt | head -n1000 > input_var_1000.txt
.PHONY: input


run: run1 run2 mem
.PHONY: run


run1:
	@echo "Compile: C (recursive)"
	@gcc -O3 -march=native -flto -pipe -o c_recursive c_recursive.c
	@echo "Starting measurements: C (recursive) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./c_recursive -n 3"
	@echo "Starting measurements: C (recursive) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./c_recursive -n 3"
	@echo "Starting measurements: C (recursive) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./c_recursive -n 5"
	@echo "Starting measurements: C (recursive) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./c_recursive -n 5"
	@echo "Compile: C (iterative: reusable n-gram sized buffer)"
	@gcc -O3 -march=native -flto -pipe -o c_iterative c_iterative.c
	@echo "Starting measurements: C (iterative: reusable n-gram sized buffer) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./c_iterative -n 3"
	@echo "Starting measurements: C (iterative: reusable n-gram sized buffer) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./c_iterative -n 3"
	@echo "Starting measurements: C (iterative: reusable n-gram sized buffer) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./c_iterative -n 5"
	@echo "Starting measurements: C (iterative: reusable n-gram sized buffer) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./c_iterative -n 5"
	@echo "Compile: C (iterative2: many small writes)"
	@gcc -O3 -march=native -flto -pipe -o c_iterative2 c_iterative2.c
	@echo "Starting measurements: C (iterative2: many small writes) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./c_iterative2 -n 3"
	@echo "Starting measurements: C (iterative2: many small writes) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./c_iterative2 -n 3"
	@echo "Starting measurements: C (iterative2: many small writes) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./c_iterative2 -n 5"
	@echo "Starting measurements: C (iterative2: many small writes) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./c_iterative2 -n 5"
	@echo "Compile: C (iterative3: large buffer, need length computations)"
	@gcc -O3 -march=native -flto -pipe -o c_iterative3 c_iterative3.c
	@echo "Starting measurements: C (iterative3: large buffer, need length computations) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./c_iterative3 -n 3"
	@echo "Starting measurements: C (iterative3: large buffer, need length computations) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./c_iterative3 -n 3"
	@echo "Starting measurements: C (iterative3: large buffer, need length computations) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./c_iterative3 -n 5"
	@echo "Starting measurements: C (iterative3: large buffer, need length computations) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./c_iterative3 -n 5"
	@echo "Starting measurements: AWK (recursive) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./awk_recursive.sh 3"
	@echo "Starting measurements: AWK (recursive) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./awk_recursive.sh 3"
	@echo "Starting measurements: AWK (recursive) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./awk_recursive.sh 5"
	@echo "Starting measurements: AWK (recursive) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./awk_recursive.sh 5"
	@echo "Starting measurements: AWK (iterative) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./awk_iterative.sh 3"
	@echo "Starting measurements: AWK (iterative) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./awk_iterative.sh 3"
	@echo "Starting measurements: AWK (iterative) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./awk_iterative.sh 5"
	@echo "Starting measurements: AWK (iterative) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./awk_iterative.sh 5"
	@echo "Starting measurements: PERL (iterative) 3-gram, fixed-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_fix.txt | ./perl_iterative.pl -n 3"
	@echo "Starting measurements: PERL (iterative) 3-gram, variable-length fields, padding 10 000 lines"
	@./timeit.sh 3 "cat input_var.txt | ./perl_iterative.pl -n 3"
	@echo "Starting measurements: PERL (iterative) 5-gram, fixed-length fields, padding words 1 000 lines"
	@./timeit.sh 3 "cat input_fix.txt  | head -n1000 | ./perl_iterative.pl -n 5"
	@echo "Starting measurements: PERL (iterative) 5-gram, variable-length fields, padding 1 000 lines"
	@./timeit.sh 3 "cat input_var.txt | head -n1000 | ./perl_iterative.pl -n 5"
.PHONY: run1


run2:
	@echo "Starting measurements: time python var-algs 3-gram, fixed-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix.txt -n 3 -u padding -r all-variable -m False -w False
	@echo "Starting measurements: time python var-algs 3-gram, variable-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_var.txt -n 3 -u padding -r all-variable -m False -w False
	@echo "Starting measurements: time python var-algs 5-gram, fixed-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 5 -u padding -r all-variable -m False -w False
	@echo "Starting measurements: time python var-algs 5-gram, variable-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_var_1000.txt -n 5 -u padding -r all-variable -m False -w False
	@echo "Starting measurements: time python fix-algs 3-gram, fixed-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix.txt -n 3 -f 3 -u no-padding -r all-fixed -m False -w False
	@echo "Starting measurements: time python fix-algs 5-gram, fixed-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 5 -f 3 -u no-padding -r all-fixed -m False -w False
	@echo "Starting measurements: time python init time no-padding"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 3 -f 3 -u no-padding -r init -m False -w False
	@echo "Starting measurements: time python init time padding"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 3 -f 3 -u padding -r init -m False -w False
.PHONY: run2


mem:
	@echo "Starting measurements: mem python var-algs 3-gram, fixed-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix.txt -n 3 -u padding -r all-variable -m True -w False
	@echo "Starting measurements: mem python var-algs 3-gram, variable-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_var.txt -n 3 -u padding -r all-variable -m True -w False
	@echo "Starting measurements: mem python var-algs 5-gram, fixed-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 5 -u padding -r all-variable -m True -w False
	@echo "Starting measurements: mem python var-algs 5-gram, variable-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_var_1000.txt -n 5 -u padding -r all-variable -m True -w False
	@echo "Starting measurements: mem python fix-algs 3-gram, fixed-length fields, padding 10 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix.txt -n 3 -f 3 -u no-padding -r all-fixed -m True -w False
	@echo "Starting measurements: mem python fix-algs 5-gram, fixed-length fields, padding 1 000 lines"
	@./venv/bin/poetry run python3 ngram.py -i input_fix_1000.txt -n 5 -f 3 -u no-padding -r all-fixed -m True -w False
.PHONY: mem


format_run1:
	@make run1 > result1.txt && ./venv/bin/poetry run python3 format_run1.py result1.txt result1.xlsx


clean:
	@ echo "Cleaning up"
	@rm -rf venv input_fix.txt input_var.txt input_fix_1000.txt input_var_1000.txt result1.txt c_recursive c_iterative c_iterative2 c_iterative3
.PHONY: clean
