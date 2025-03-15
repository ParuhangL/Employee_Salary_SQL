-- CREATE DATABASE employee_db;
-- USE employee_db;

CREATE TABLE Department(
	department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Employee(
	employee_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    department_id INT,
    Hire_Date DATE DEFAULT (CURDATE()),
    FOREIGN KEY (department_id) REFERENCES Department (department_id) ON DELETE SET NULL
);

CREATE TABLE Salaries(
	salary_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    amount DECIMAL(10,2) NOT NULL,
    pay_date DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE
);

INSERT INTO department(department_name)
VALUES ('HR'), ('IT'),('Sales');

INSERT INTO employee(full_name, email, department_id)
VALUES 
('Alice Johnson', 'alice@example.com', 1 ),
('Bob Smith', 'bob@example.com', 2),
('Charlie Brown', 'charlie@example.com', 3);

INSERT INTO salaries (employee_id, amount, pay_date)
VALUES 
(1, 5000, '2025-03-01'),
(2, 7000, '2025-03-01'),
(3, 4500, '2025-03-01');

# Fetch employees by department
SELECT e.full_name,e.email, d.department_name 
FROM employee AS e
JOIN department AS d ON e.department_id = d.department_id
WHERE d.department_id = 1; # Find individual department
-- ORDER BY d.department_name; # Fetch all department

#Generate Salary report
SELECT e.full_name, s.amount, s.pay_date
FROM salaries AS s
JOIN employee AS e ON e.employee_id = s.employee_id
ORDER BY s.amount ASC;

# Creating index for faster queries
CREATE INDEX idx_department_id ON Employee(department_id);
CREATE INDEX idx_employee_id ON salaries(employee_id);

# Create View to get Employee, their department and salary
CREATE VIEW salary_report AS
SELECT e.full_name AS Full_Name, d.department_name as Department, s.amount AS Salary
FROM employee AS e
JOIN department AS d ON e.department_id = d.department_id
JOIN Salaries AS s ON e.employee_id = s.employee_id;

# Create a stored procedure to get salary history of an employee
DELIMITER $$
CREATE PROCEDURE `GetEmployeeSalary`(IN emp_id INT)
BEGIN
	SELECT e.full_name, s.amount, s.pay_date
    FROM salaries AS s
    JOIN employee AS e ON s.employee_id = e.employee_id
    WHERE e.employee_id = emp_id
    ORDER BY s.pay_date DESC;
END $$
DELIMITER ;

# Call procedure to execute the store procedure
CALL GetEmployeeSalary(1);

# Update salary if the increased amount is same using Transaction
START TRANSACTION;
UPDATE salaries
SET amount = amount + 1000
WHERE employee_id IN (1,2);
COMMIT;

# Update salary if the increase amount is different for each employee  using TRANSACTION
START TRANSACTION;
UPDATE salaries
SET amount = CASE
	WHEN employee_id = 3 THEN amount + 2000
    WHEN employee_id = 4 THEN amount + 2500
    ELSE amount
END
WHERE employee_id IN (3,4);
COMMIT;

# Create a user and GRANT or REVOKE permissions
CREATE USER 'hr_user'@'localhost' IDENTIFIED BY 'hr_password';
GRANT SELECT ON salaries TO 'hr_user'@'localhost';
REVOKE UPDATE, DELETE ON salaries FROM 'hr_user'@'localhost';
# To make the user privileges take effect immediately
FLUSH PRIVILEGES;
# Return current user
SELECT CURRENT_USER();

# Using CASE statement to categorize employee by salary
SELECT e.full_name AS `Name`, s.amount AS Salary,
CASE
	WHEN s.amount < 4000 THEN 'LOW'
    WHEN s.amount BETWEEN 4000 AND 8000 THEN 'MEDIUM'
	ELSE 'HIGH'
END AS salary_category
FROM salaries AS s
JOIN employee AS e ON s.employee_id = e.employee_id;

# Using CTE to find employees with above average salaries
WITH avg_Salary AS(
	SELECT AVG(amount) AS average_Salary FROM salaries
)
SELECT e.full_name, s.amount
FROM salaries AS s
JOIN employee AS e ON s.employee_id = e.employee_id
JOIN avg_Salary AS a WHERE s.amount > a.average_Salary;

# Use Window Function to RANK employee based on salary

SELECT e.full_name AS `Name`, d.department_name AS Department, s.amount,
	RANK() OVER (PARTITION BY d.department_name ORDER BY s.amount DESC) AS Salary_rank
FROM employee AS e
JOIN department AS d ON e.department_id = d.department_id
JOIN salaries AS s ON e.employee_id = s.employee_id;

# Event that automatically increase salary by 5% yearly
CREATE EVENT yearly_salary_increase
ON SCHEDULE EVERY 1 YEAR
DO
UPDATE salaries SET amount = amount * 1.05;
# Enable the event scheduler
SET GLOBAL event_scheduler = ON;

# Trigger to prevent salaries from decreasing below 5000
DELIMITER $$
CREATE TRIGGER prevent_low_Salary
BEFORE UPDATE ON salaries
FOR EACH ROW
BEGIN
	IF NEW.amount < 5000 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary cannot be less than 5000';
	END IF;
END $$
DELIMITER ;

