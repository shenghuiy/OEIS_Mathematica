/* SCIP solver for src/wolfram/A401118.wl (Method -> "SCIP"), loaded there with ForeignFunctionLoad.

   Maximizes sum w[j] x[j] over 0-1 x subject to sum_{j in clique c} x[j] <= 2.
   Cliques are given in CSR form: clique c is clidx[clstart[c]] .. clidx[clstart[c+1] - 1], 0-based.
   A positive timelimit is passed to SCIP's limits/time.
   Returns the optimal value rounded to an integer and writes x to xout, or a negative code on failure:
   -2 a SCIP call failed, -3 SCIPcreate failed, -4 a clique has more than 64 elements, -5 not solved to optimality. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "scip/scip.h"
#include "scip/scipdefplugins.h"

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#define CHECK(call) do { if ((call) != SCIP_OKAY) { status = -2; goto TERMINATE; } } while (0)

EXPORT int a401118_scip_max(int nv, const double* w, int ncl, const int* clstart, const int* clidx,
                            double timelimit, int* xout)
{
   SCIP* scip = NULL;
   SCIP_VAR** vars = NULL;
   SCIP_SOL* sol;
   int status = -1;
   int c, j;
   char name[32];

   if (SCIPcreate(&scip) != SCIP_OKAY)
      return -3;
   CHECK( SCIPincludeDefaultPlugins(scip) );
   CHECK( SCIPsetIntParam(scip, "display/verblevel", 0) );
   if (timelimit > 0)
      CHECK( SCIPsetRealParam(scip, "limits/time", timelimit) );
   CHECK( SCIPcreateProbBasic(scip, "a401118") );
   CHECK( SCIPsetObjsense(scip, SCIP_OBJSENSE_MAXIMIZE) );

   vars = (SCIP_VAR**) calloc((size_t) nv, sizeof(SCIP_VAR*));
   for (j = 0; j < nv; ++j)
   {
      snprintf(name, sizeof(name), "x%d", j);
      CHECK( SCIPcreateVarBasic(scip, &vars[j], name, 0.0, 1.0, w[j], SCIP_VARTYPE_BINARY) );
      CHECK( SCIPaddVar(scip, vars[j]) );
   }

   for (c = 0; c < ncl; ++c)
   {
      SCIP_CONS* cons;
      int len = clstart[c + 1] - clstart[c];
      SCIP_VAR* cv[64];
      double ones[64];
      if (len > 64) { status = -4; goto TERMINATE; }
      for (j = 0; j < len; ++j) { cv[j] = vars[clidx[clstart[c] + j]]; ones[j] = 1.0; }
      snprintf(name, sizeof(name), "c%d", c);
      CHECK( SCIPcreateConsBasicLinear(scip, &cons, name, len, cv, ones, -SCIPinfinity(scip), 2.0) );
      CHECK( SCIPaddCons(scip, cons) );
      CHECK( SCIPreleaseCons(scip, &cons) );
   }

   CHECK( SCIPsolve(scip) );
   if (SCIPgetStatus(scip) != SCIP_STATUS_OPTIMAL) { status = -5; goto TERMINATE; }
   sol = SCIPgetBestSol(scip);
   for (j = 0; j < nv; ++j)
      xout[j] = SCIPgetSolVal(scip, sol, vars[j]) > 0.5;
   status = (int) floor(SCIPgetSolOrigObj(scip, sol) + 0.5);

TERMINATE:
   if (vars != NULL)
   {
      for (j = 0; j < nv; ++j)
         if (vars[j] != NULL)
            SCIPreleaseVar(scip, &vars[j]);
      free(vars);
   }
   SCIPfree(&scip);
   return status;
}
