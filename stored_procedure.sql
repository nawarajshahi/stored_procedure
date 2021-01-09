-- ==================================================
/* 
(1) Stored procedure to return the average salary by department
NOTE: user has to specify which department nad below you can see
all the departments that a user can specify to check avg salary for
	Customer Service
	Development
	Finance
	Human Resources
	Marketing
	Production
	Quality Management
	Research
	Sales
*/

DELIMITER //
CREATE PROCEDURE avgSalaryByDept(IN department_name varchar(50), OUT avgSalary float)
BEGIN
	SELECT avg(salary) INTO avgSalary
    FROM salaries 
    INNER JOIN dept_emp USING(emp_no)
    INNER JOIN departments d USING(dept_no)
    WHERE d.dept_name = department_name;
select avgSalary AS 'Average Salary';
END //
DELIMITER ;

-- call the stored procedure named avgSalaryByDept()
call avgSalaryByDept('Finance', @avgSalary);
-- ==================================================

/*
(2) stored procedure to that returns the first_name, last_name and title of the manager. 
NOTE: I'll be using this procedure later to call from another procedure.
You can use the employee_id which are listed below:
110022, 110039, 110085, 110114, 110183, 110228, 110303, 110344, 110386, 110420, 
110511, 110567, 110725, 110765, 110800, 110854, 111035, 111133, 111400, 111534, 
111692, 111784, 111877, 111939
*/

delimiter //
CREATE PROCEDURE getManagerDetails(
    IN employee_id INT,
    OUT fullName varchar(255),
    OUT emp_title varchar(50)
)
BEGIN
    DECLARE firstName varchar(50);
    DECLARE lastName varchar(50);

    SELECT e.first_name, e.last_name, t.title
        INTO firstName, lastName, emp_title
    FROM employees e
    INNER JOIN titles t USING(emp_no)
    WHERE e.emp_no = employee_id AND t.title = 'Manager';

    SELECT CONCAT(firstName, ' ', lastName) INTO fullName;
    SELECT @fullName AS 'Full Name', @emp_title AS 'Title';

end //
delimiter ;
call getManagerDetails(110022, @fullName, @emp_title);
-- ==================================================

/*
(3) stored procedure to identify the number of years that an employee has served as the title of 'Manager'
NOTE: manager details can be located using dept_manager table. 
You can use the employee_id which are listed below:
	110022, 110039, 110085, 110114, 110183, 110228, 110303, 110344, 110386, 110420, 
	110511, 110567, 110725, 110765, 110800, 110854, 111035, 111133, 111400, 111534, 
	111692, 111784, 111877, 111939
*/

delimiter //
create procedure managerTenureYears(IN manager_id INT, OUT years varchar(100))
BEGIN
    DECLARE beginYear int;
    DECLARE endYear int;

    select year(t.from_date), year(t.to_date)
    INTO beginYear, endYear
    FROM titles t
    WHERE t.emp_no = manager_id AND t.title = 'Manager';

    -- There might be multiple employees who have served as manager for the
    -- department. In the database, the most recent manager has year set to
    -- 9999 which is why we need to set this to current date
    IF endYear = 9999 THEN
        SET endYear = year(now());
        SELECT CONCAT(manager_id, ' as of now has served ', endYear - beginYear, ' years') INTO years;
        SELECT @years;
    ELSE
        SELECT CONCAT(manager_id, ' served ', endYear - beginYear, ' years') INTO years;
        SELECT @years;
    end if;
end //
delimiter ;
call managerTenureYears(110022, @years);
-- ==================================================

/*
(4) stored procedure that uses results from (2) and (3) to give more detailed information
Just like in (2) and (3). you can use the following employee_ids: 
	110022, 110039, 110085, 110114, 110183, 110228, 110303, 110344, 110386, 110420, 
	110511, 110567, 110725, 110765, 110800, 110854, 111035, 111133, 111400, 111534, 
	111692, 111784, 111877, 111939
NOTE: I choose this approach to show that other procedures can be called and alter 
the output as desired. 
*/

DELIMITER //
CREATE PROCEDURE managerConcreteDetail(IN manager_id INT)
BEGIN
    DECLARE department_name varchar(50);
    SELECT dept_name
        INTO department_name
    FROM departments
    INNER JOIN dept_emp de on departments.dept_no = de.dept_no
    WHERE de.emp_no = manager_id;

    CALL getManagerDetails(manager_id, @fullName, @emp_title);
    CALL managerTenureYears(manager_id, @years);
    SELECT CONCAT(@fullName, ' with employee id: ', @years, ' as the ',
        @emp_title, ' for the ', department_name, ' department.') AS 'Manager Details';
end //
DELIMITER ;
CALL managerConcreteDetail(110022);
-- ==================================================

/*
(5) stored procedure to obtain the total salary disbursed in a given tax year
NOTE: User must specify beginning and end date of the tax year
	For example: '1990-01-01' AND '1990-12-31'
*/

delimiter //
create procedure totalSalaryByTaxYear(IN begin date, IN end date, OUT totalSalary varchar(255), OUT taxYear year)
BEGIN
    select concat('$', FORMAT(sum(salary),0))
        INTO totalSalary
    FROM salaries
        WHERE from_date >= begin AND to_date <= end;

    SET taxYear = year(begin);
    SELECT @totalSalary, @taxYear;
end //
delimiter ;

CALL totalSalaryByTaxYear('1990-01-01', '1990-12-31', @totalSalary, @taxYear);


