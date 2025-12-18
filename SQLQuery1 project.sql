create database library_system
use library_system


CREATE TABLE Library(
    library_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(50) NOT NULL UNIQUE,
    location NVARCHAR(50) NOT NULL,
    contact_number NVARCHAR(15) NOT NULL,
    establish_year INT NOT NULL
);
CREATE TABLE book(
    book_id INT PRIMARY KEY IDENTITY(1,1),
    title NVARCHAR(100) NOT NULL,
    genre NVARCHAR(20) NOT NULL CHECK (genre IN ('Fiction','Non-fiction','Reference','Children')),
    shelf_location NVARCHAR(50) NOT NULL,
    availability_status BIT NOT NULL DEFAULT 1, -- TRUE = available
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    ISBN BIGINT NOT NULL UNIQUE,
    library_id INT NOT NULL,
    FOREIGN KEY (library_id) REFERENCES library(library_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE members(
    member_id INT PRIMARY KEY IDENTITY(1,1),
    full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(50) NOT NULL UNIQUE,
    phone_number NVARCHAR(15),
    membership_start_date DATE NOT NULL
);
CREATE TABLE staff(
    staff_id INT PRIMARY KEY IDENTITY(1,1),
    full_name NVARCHAR(100) NOT NULL,
    position NVARCHAR(50) NOT NULL,
    contact_number NVARCHAR(15),
    library_id INT NOT NULL,
    FOREIGN KEY (library_id) REFERENCES library(library_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE loan(
    loan_id INT PRIMARY KEY IDENTITY(1,1),
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'Issued'
        CHECK (status IN ('Issued','Returned','Overdue')),

    CONSTRAINT chk_return_date
        CHECK (return_date IS NULL OR return_date >= loan_date),

    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (book_id) REFERENCES book(book_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE fine_payment(
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    loan_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    payment_method NVARCHAR(50) NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE review(
    review_id INT PRIMARY KEY IDENTITY(1,1),
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments NVARCHAR(250) NOT NULL DEFAULT 'No comments',
    review_date DATE NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book(book_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

INSERT INTO library (name, location, contact_number, establish_year)
VALUES 
('Muscat Central Library', 'Muscat', '96892412398', 1998),
('Salalah Public Library', 'Salalah', '96898232198', 2009);

INSERT INTO members (full_name, email, phone_number, membership_start_date)
VALUES
('Ahmed Al-Harthy', 'ahmed.harthy@gmail.com', '0096891234567', '2023-01-10'),
('Fatma Al-Zadjali', 'fatma.z@gmail.com', '0096898765432', '2023-02-05');

INSERT INTO book (title, genre, shelf_location, price, ISBN, library_id)
VALUES
('Oman History', 'Non-fiction', 'Shelf A1', 150.00, 9789996901234, 1),
('SQL Fundamentals', 'Reference', 'Shelf B2', 120.00, 9780133970777, 1),
('Arabian Tales', 'Fiction', 'Shelf C3', 85.00, 9781402894626, 2);

INSERT INTO staff (full_name, position, contact_number, library_id)
VALUES
('Saeed Al-Rashdi', 'Head Librarian', '96898877665', 1),
('Muna Al-Hinai', 'Library Assistant', '96896655443', 2);

INSERT INTO loan (member_id, book_id, loan_date, due_date)
VALUES
(1, 1, '2023-04-01', '2023-04-15'),
(2, 2, '2023-04-05', '2023-04-20');

INSERT INTO fine_payment (loan_id, payment_date, amount, payment_method)
VALUES
(1, '2023-04-18', 10.00, 'Cash');

INSERT INTO review (member_id, book_id, rating, review_date)
VALUES
(1, 1, 5, '2023-04-12');

INSERT INTO review (member_id, book_id, rating, comments, review_date)
VALUES
(2, 2, 4, 'Very informative book', '2023-04-15');

--6) Library Database – DQL & DML Tasks 
--DQL 
--1. Display all book records. 
select * from book
--2. Display each book’s title, genre, and availability. 
select title,genre,availability_status from book
--3. Display all member names, email, and membership start date.
select full_name,email,membership_start_date from members
--4. Display each book’s title and price as BookPrice. 
select  title,price as BookPrice from book
select * from book
--5. List books priced above 110 LE. 
select * from book where price > 110
--6. List members who joined before 2025. 
select * from members where membership_start_date < '01-01-2025'
--8. Display books ordered by price descending.
select * from book  order by price desc
--9. Display the maximum, minimum, and average book price. 
SELECT 
    MAX(price) AS MaxPrice,
    MIN(price) AS MinPrice,
    AVG(price) AS AvgPrice
FROM book;
--10. Display total number of books. 
SELECT COUNT(*) AS TotalBooks
FROM book;
--11. Display members with NULL email. 
select * from members where email is null
--12. Display books whose title contains 'stor'. 
SELECT *
FROM book
WHERE title LIKE '%stor%';
--DML 
--13. Insert yourself as a member (Member ID = 405). 
SET IDENTITY_INSERT members ON;
INSERT INTO members (member_id, full_name, email, phone_number, membership_start_date)
VALUES (405, 'Elham AlBalushiah', 'alhamalbalushiah@gmail.com', '94454699', '2024-08-18');
SET IDENTITY_INSERT members OFF;
--14. Register yourself to borrow book ID 1011. 
INSERT INTO loan (member_id, book_id, loan_date, due_date)
VALUES (405, 1011, GETDATE(), DATEADD(day, 14, GETDATE()));
--15. Insert another member with NULL email and phone. 
email NVARCHAR(30) NOT NULL --This insertion is not allowed due to NOT NULL constraint on email

--16. Update the return date of your loan to today.
UPDATE loan
SET return_date = GETDATE(),
    status = 'Returned'
WHERE member_id = 405;
--17. Increase book prices by 5% for books priced under 200. 
UPDATE book
SET price = price * 1.05
WHERE price < 200;
--18. Update member status to 'Active' for recently joined members. 

--19. Delete members who never borrowed a book.
DELETE FROM members
WHERE member_id NOT IN (
    SELECT DISTINCT member_id
    FROM loan
);