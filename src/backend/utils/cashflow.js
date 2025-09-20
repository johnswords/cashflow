const getNumber = value => {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.trim() !== "") return Number(value);
  return 0;
};

const sumArray = (items, key) => {
  if (!Array.isArray(items)) return 0;
  return items.reduce((acc, item) => acc + getNumber(item?.[key]), 0);
};

const getIncomeState = sheet => sheet?.income ?? {};
const getExpensesState = sheet => sheet?.expenses ?? {};
const getInvestmentsState = sheet => sheet?.investments ?? {};
const getLiabilitiesState = sheet => sheet?.liabilities ?? {};

const computePassiveIncome = sheet => {
  const incomeState = getIncomeState(sheet);
  const investmentsState = getInvestmentsState(sheet);

  return (
    getNumber(incomeState.interest?.value) +
    getNumber(incomeState.interest2?.value) +
    sumArray(investmentsState.realEstate, "income") +
    sumArray(investmentsState.businesses, "income")
  );
};

const computeTotalIncome = sheet => {
  const incomeState = getIncomeState(sheet);
  const salary = getNumber(incomeState.salary?.value ?? incomeState.salary);
  return salary + computePassiveIncome(sheet);
};

const computeChildExpenses = sheet => {
  const expensesState = getExpensesState(sheet);
  const children = expensesState.children ?? {};
  return getNumber(children.numberOfChildren) * getNumber(children.perChildExpense);
};

const computeBankLoanExpense = sheet => {
  const liabilities = getLiabilitiesState(sheet);
  return Math.round(getNumber(liabilities.bankLoan) / 10);
};

const computeTotalExpenses = sheet => {
  const expensesState = getExpensesState(sheet);
  return (
    getNumber(expensesState.taxes?.value) +
    getNumber(expensesState.mortgage?.value) +
    getNumber(expensesState.schoolLoan?.value) +
    getNumber(expensesState.carLoan?.value) +
    getNumber(expensesState.creditCard?.value) +
    getNumber(expensesState.retail?.value) +
    getNumber(expensesState.other?.value) +
    computeBankLoanExpense(sheet) +
    computeChildExpenses(sheet) +
    getNumber(expensesState.miscellaneousExpense?.value)
  );
};

const computeCashflow = sheet => computeTotalIncome(sheet) - computeTotalExpenses(sheet);

module.exports = { computeCashflow, computeTotalIncome, computeTotalExpenses, computePassiveIncome };
