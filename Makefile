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


run:
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
.PHONY: run


clean:
	@ echo "Cleaning up"
	@rm -rf venv input_fix.txt input_var.txt input_fix_1000.txt input_var_1000.txt
.PHONY: clean
