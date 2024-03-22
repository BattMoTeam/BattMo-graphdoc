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
reusability**. A user who wants to modify an existing model will typically be interested in keeping most of the
existing models, and reuse the variable update functions that are been defined there. Looking at the graph, we
can understand the dependency easily and identify the part that should be changed in the model. In some cases,
the dependency graph may not changed, only a different function should be called to update a variable. For
example, the exchange current density function :math:`j` rarely obeys the ideal case presented above but is a
given tabulated function,

.. math::

   j(c_e, c_s) = \hat{j}(c_s, c_s)


where :math:`\hat{j}` is a given function the user has set up. Such function is an example of a functional
parameter belonging to the model, which we mentioned earlier.

Continuing with the same example, we may introduce a temperature dependency in the OCP function. We have

.. math::

   \text{OCP} = \hat{\text{OCP}}(c_s, T)

Then, we have to introduce a new node (i.e. variable) in our graph, the temperature :code:`T`.

.. image:: img/reacmodelgraph2.png

Let us introduce an other model, at least its computational graph. We consider a simple heat equation

.. math::

   \alpha T_t = \nabla\cdot(\lambda \nabla T) + q


We introduce in addition to the temperature :code:`T` the following variable names (nodes) and, in the right
column, we write the definition they will take after discretization. The operators :code:`div` and
:code:`grad` denotes the discrete differential operators used in the assembly.

+------------+--------------------------------------------------------------------+
| accumTerm  | :math:`\alpha\frac{T - T^0}{\Delta t}`                             |
+------------+--------------------------------------------------------------------+
| flux       | :math:`-\lambda\text{grad}(T)`                                     |
+------------+--------------------------------------------------------------------+
| sourceTerm | :math:`q`                                                          |
+------------+--------------------------------------------------------------------+
| energyCons | :math:`\text{accumTerm} + \text{div}(\text{flux}) + \text{source}` |
+------------+--------------------------------------------------------------------+

The computational for the temperature model is given by

.. image:: img/tempgraph.png

Having now two models, we can illustrate how we can combine the corresponding computational graph to obtain a
coupled model. Let us couple the two models in two ways. We include a heat source produced by the chemical
reaction, as some function of the reaction rate. The effect of the temperature on the chemical reaction is
included, as we presented earlier, as a additional temperature dependence of the open circuit potential
:code:`OCP`. We obtain the following computational graph

.. image:: img/tempreacgraph.png

In the node names, we recognize the origin of variable through a model name, either :code:`Reaction` or
:code:`Thermal`. We will come back later to that.

With this model, we can setup our first simulation. Given the concentrations and potentials, we want to obtain
the temperature, which can only obtained implicitely by solving the energy equation. Looking at the graph, we
find that the root variables are :code:`Thermal.T`, :code:`Reaction.c_s`, :code:`Reaction.phi_s`,
:code:`Reaction.c_e`, :code:`Reaction.phi_e`. The tail variable is the energy conservation equation
:code:`energyCons`. A priori, the system looks well-posed with same number of unknown and equation (one of
each). At this stage, we want our implementation to automatically detects the primary variables (the root node,
:code:`T`) and the equations (the tail node, :code:`energyCons`) and to proceed with the assembly by traversing
the graph. We will later how it is done.

To conclude this example, we introduce a model for the concentrations and make them time dependent. In the
earlier model, the concentrations were kept constant because, for example, access to an infinite reservoir of
the chemical species. Now, we consider the case of a closed reservoir and the composition evolve accordingly to
the chemical reaction. We have equations of the form

.. math::

   \begin{align*}
   \frac{dc_s}{dt} &= R_s, & \frac{dc_r}{dt} &= R_e 
   \end{align*}
   
where the right-hand side is obtained from the computed reaction rate, following the stoichiometry of the
chemical reactions.

The computational grap for each of this equation take the generic form

.. image:: img/concgraph.png

where

+------------+--------------------------------------+
| masssAccum | :math:`\frac{c - c^0}{\Delta t}`     |
+------------+--------------------------------------+
| source     | :math:`R`                            |
+------------+--------------------------------------+
| massCons   | :math:`\frac{c - c^0}{\Delta t} - R` |
+------------+--------------------------------------+

Let us now combine this model with the first one, which provided us with te computation of the chemical
reaction rate. We need two instance of the concentration model. To solve, the issue of **duplicated** variable
name, we add indices in our notations but this cannot be robustly scaled to large model. Instead, we introduce
model names and a model hierarchy. This was done already earlier with the :code:`Thermal` and :code:`Reaction`
models. Let us name our two concentration models as :code:`Solid` and :code:`Elyte`. We obtain the following
graph.

.. image:: img/concreacgraph.png 

We note that it becomes already difficult to read off the graph and it will become harder and harder as model
grow. We have developped visualization tool that will help us in exploring the model through their graphs.

Given :code:`phi_s` and :code:`phi_e`, we can solve the problem of computing the evolution of the
concentrations. The *root* nodes are the two concentrations (the potentials are known) and the *tail* nodes are
the mass conservation equations.

Finally, we can couple the model above with with the temperature, by *sewing* together the graphs. We name the
previous composite model as :code:`Masses` and keep the name of :code:`Thermal` for the thermal model. We
obtain the following

.. image:: img/tempconcreacgraph.png

New computational graphs are thus obtained by connecting existing graph, using a hierarchy of model. In the
example above, the model hierarchy is given by

.. image:: img/tempconcreacgraphmodel.png





           
   
