===========================================
Computation Graph Model Design ang Assembly
===========================================

A model is a computational graph. We have identified variables. Variables are dependent one from the other. The
dependence can be explicit or implicit. In the explicit case, a variable can be directly computed from the
other using a function evaluation. In the implicit case, such function does not exist in a simple form. The
relationship between the variables is given through equations. The purpose of our simulations is to solve these
equations. The equations are added to the system of non-linear equation we solve, at each time step in the case
of an evolution problem.

In the computational graph, the nodes are given by the variables in the model. The directed edges represent the
functional dependency between the variables

A simple introduction example
=============================

Let us consider the example of a reaction model. The reaction rate :math:`R` is given
by

.. math::
   :nowrap:

   \begin{align*}
   R &= j\left(e^{-\alpha\frac{\eta}{RT}} + e^{(1-\alpha)\frac{\eta}{RT}}\right)\\
   j&= k c_s(1 - c_e)^{\frac12}c_e^\frac12\\
   \eta &= \phi_s - \phi_e - \text{OCP}\\
   \text{OCP} &= \hat{\text{OCP}}(c_s)
   \end{align*}

We have seven variables :math:`R,\ j, \eta, \text{OCP}, \phi_s, \phi_e, c_s, c_e`. The dependency graph we
obtain from the equations above is

.. image:: img/reacmodelgraph.png

This graph has been obtained in BattMo after we implemented the model. We will explain later how this can be
done (for the impatient, see here)

The graph is a `directed acyclic graph <https://en.wikipedia.org/wiki/Directed_acyclic_graph>`_, meaning that
it has no loop. We can thus identify *root* and *tail* variables. In the case above, the root variables are
:math:`\phi_s, \phi_e, c_s, c_e` and there only one tail variable, :math:`R`. Given values for the root
variables, we can traverse the graph and evaluate all the intermediate variables to compute the tail
variables. To evaluate variables, the functions we will implement will always need parameters (the opposite
case where a function can be defined without any external parameters is expected to be rare in a physical
context). Then, we can describe our model with

* A set of parameters (scalar variables, but maybe also functions)
* A computational graph
* A set of functions associated to each node (i.e. variable) which as an incoming edge in the computational
  graph

For each of the function in the set above, we know the input and output arguments. They are given by the nodes
connected by the edge.

The motivation for introducing suuch graph representation is **expressivity**. It provides a synthetic overview
of the model. Of course, the precise expression of the functions, which is not visible in the graph, is an
essential part. All the physics is encoded there. But, the graph gives us access to the dependency between the
variables and the variables have been chosen by the user in the model because of their specific physical
meaning. The user has chosen them from a physical insight, that we want to preserve. Especially when we expand
the models. In our previous examples, the variables we have introduced have all a name meaningfull for the
expert in the domains.

+--------------+--------------------------------------+
| R            | Reaction Rate                        |
+--------------+--------------------------------------+
| j            | Exchange Current Density             |
+--------------+--------------------------------------+
| eta          | Over-potential                       |
+--------------+--------------------------------------+
| OCP          | Open Circuit Potential               |
+--------------+--------------------------------------+
| phi_s, phi_e | Solid and Electrolyte potentials     |
+--------------+--------------------------------------+
| c_s, c_e     | Solid and Electrolyte concentrations |
+--------------+--------------------------------------+

A user can inspect a given model first by looking at the graph, recognized the variables that are named
here. They should be meaningfull to him, as they should have been chosen to correspond to a given domain
expertise terminology (here electrochemistry).

Let us now see how we can compose computational graph

Graph composition
=================

This model representation as a graph brings also **flexibility** in model building and in particular **code
reusability**.










