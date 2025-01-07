function tests = tstExample_solverTest
tests = functiontests(localfunctions);
return

function testRealSolution(testCase)
actSolution = tstExample_quadraticSolver(1,-3,2);
expSolution = [2 1];
verifyEqual(testCase,actSolution,expSolution)
return

function testImaginarySolution(testCase)
actSolution = tstExample_quadraticSolver(1,2,10);
expSolution = [-1+3i -1-3i];
verifyEqual(testCase,actSolution,expSolution)
return

function testBadRealSolution(testCase)
actSolution = tstExample_quadraticSolver(1,3,2);
expSolution = [2,1];
testCase.verifyEqual(actSolution,expSolution)
return