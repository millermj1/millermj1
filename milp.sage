# Written by Michael J Miller (Le Moyne College) - last revised 20-Jan-2020
# Linear programming code for MTH-120 sagecell
# Load into sagecell with: 
#    load('https://web.lemoyne.edu/millermj/mth120/MILP.sage')

# may need as .py 
#implicit_multiplication(10)
#########################################


r"""
Print the solution to a mixed integer linear program.

Variables are assumed real unless specified as integer,
and all variables are assumed to be nonnegative.

EXAMPLES::

var('x1 x2')
maximize(20*x1 + 10*x2, {3*x1 + x2 <= 1300, x1 + 2*x2 <= 600, x2 <= 250})
# Z = 9000.0, x1 = 400.0, x2 = 100.0

var('s h a u')
maximize(0.05*s + 0.08*h + 0.10*a + 0.13*u, {a <= 0.30*(h+a), 
      s <= 300, u <= s, u <= 0.20*(h+a+u), s+h+a+u <= 2000})
# Z = 174.4, s = 300.0, u = 300.0, h = 980.0, a = 420.0

var('a b c d', domain='integer')
maximize(5*a + 7*b + 2*c + 10*d, 
      {2*a + 4*b + 7*c + 10*d <= 15, a <= 1, b <= 1, c <= 1, d <=1 })
# Z = 17.0, a = 0, b = 1, c = 0, d = 1   (Note that integer variables <=1 are binary.)

var('x y')
minimize(x + y, {x + 2*y >= 7, 2*x + y >= 6})
# Z = 4.33333333333, x = 1.66666666667, y = 2.66666666667

var('x')
var('y', domain='integer')
minimize(x + y, {x + 2*y >= 7, 2*x + y >= 6})
# Z = 4.5, x = 1.5, y = 3

var('x y', domain='integer')
minimize(x + y, {x + 2*y >= 7, 2*x + y >= 6})
# Z = 5.0, x = 2, y = 3

var('x y', domain='integer')
maximize(x + y, {x + 2*y >= 7, 2*x + y >= 6})
# GLPK: Objective is unbounded

var('x y', domain='integer')
maximize(x + y, {x + 2*y >= 7, 2*x + y <= 3})
# GLPK: Problem has no feasible solution


AUTHORS:

- Michael Miller (2019-Aug-11): initial version

"""

# ****************************************************************************
#       Copyright (C) 2019 Michael Miller
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#                  https://www.gnu.org/licenses/
# ****************************************************************************


from sage.numerical.mip import MIPSolverException

def maximize(objective, constraints):
    maxmin(objective, constraints, true)

def minimize(objective, constraints):
    maxmin(objective, constraints, false)

def maxmin(objective, constraints, flag):

    # Create a set of the original variables
    variables = set(objective.variables())
    for c in constraints:
        variables.update(c.variables())
    integer_variables = [v for v in variables if v.is_integer()]
    real_variables    = [v for v in variables if not v.is_integer()]

    # Create the MILP variables
    p = MixedIntegerLinearProgram(maximization=flag)
    MILP_integer_variables = p.new_variable(integer=True, nonnegative=True)
    MILP_real_variables = p.new_variable(real=True, nonnegative=True)

    # Substitute the MILP variables for the original variables
    # (Inconveniently, the built-in subs fails with a TypeError)
    def Subs(expr):
        const = RDF(expr.subs({v:0 for v in variables})) # the constant term
        sum_integer = sum(expr.coefficient(v) * MILP_integer_variables[v] for v in integer_variables)
        sum_real = sum(expr.coefficient(v) * MILP_real_variables[v] for v in real_variables)
        return sum_real + sum_integer + const

    objective = Subs(objective)
    constraints = [c.operator()(Subs(c.lhs()), Subs(c.rhs())) for c in constraints]

    # Set up the MILP problem
    p.set_objective(objective)
    for c in constraints:
        p.add_constraint(c)

    # Solve the MILP problem and print the results
    try:
        Z = round(p.solve(), 10)
        printstr=str(Z)+", {"
        for v in integer_variables:
            printstr=printstr + str(v) + "="+ str(int(p.get_values(MILP_integer_variables[v]))) + ", "
        for v in real_variables:
            printstr=printstr + str(v) + "=" + str(round(p.get_values(MILP_real_variables[v]), 10)) +", "
        printstr=printstr+"}"
        print(printstr)
    except MIPSolverException as msg:
        if str(msg)=="GLPK: The LP (relaxation) problem has no dual feasible solution":
            print("GLPK: Objective is unbounded")
            print
        else:
            print(str(msg))
            print


