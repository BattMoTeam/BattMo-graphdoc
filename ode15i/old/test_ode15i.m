y = getOdeVariables(state);
state = stateFromOdeVarables(y);

function [eq, eq1,eq2_tmp]=odeEqs(t,y,dy,state0,dims,model)
    y = initVariablesAD(y);

    %Look at problem output from getEquations. Identify members of list
    %in state and associate each one with an element in the array y.
    %The y -> state function is then simply the inverse mapping
    %Question: What to do with remaining variables?
    %Solved X
    state = getStateFromVariables(y,model,dims,state0); 
    %For the moment
    state0 = state;
    dt = 1e100; % dummy
    
    %% all transport terms

    %Use default forces
    forces=model.getValidDrivingForces();

    %Reshape
    tmp = model.getEquations(state,state,dt,force, []); %X
    eq1=EquationVector(tmp.problem);

    dy = initVariablesAD(dy); %X

    %Check problem object returned by getEquations
    %Charge, EI, Control do not accumulate!
    %Look at AccumTerm for mass + solid diffusion
    %These can become differentiable through AD. This is what we evaluate
    %Solved X
    tmp = model.getAccumulationterm(state);
    eq2_tmp=EquationVector(tmp);
    
    eq2 = eq2_tmp*value(dy);
    eq = value(eq1) + eq2; %Value: See AD object
end

function ret=EquationVector(eq)
    ret=[];
    for i=1:length(eq)
        ret=[ret;eq{i}];
    end
end

function f=odeFun(t, y, dy)
    [f,~,~]=odeEqs(t,y,dy);
end

function [dfdy,dfdyp]=JACodeFun(t,y,dy)
    [~,eq1,eq2]=odeEqs(t,y,dy);
    dfdy=eq1.jac;
    dfdyp=eq2.jac;
end   