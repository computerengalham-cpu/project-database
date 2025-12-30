--Write SQL queries to retrieve the following information: 
--1. Library Book Inventory Report 
--Display library name, total number of books, number of available books, and number of books currently on loan for each library.  
select * from Library
select * from book
select * from members
select * from loan
select * from members
select * from staff
select * from review
select * from fine_payment
SELECT 
    l.name AS library_name,
    COUNT(b.book_id) AS total_books,
    SUM(CASE WHEN b.availability_status = 1 THEN 1 ELSE 0 END) AS available_books,
    SUM(CASE WHEN b.availability_status = 0 THEN 1 ELSE 0 END) AS books_on_loan
FROM library l
LEFT JOIN book b ON l.library_id = b.library_id
GROUP BY l.name;
--2. Active Borrowers Analysis 
--List all members who currently have books on loan (status = 'Issued' or 'Overdue'). Show member name, email, book title, loan date, due date, and current status.  
SELECT 
    m.full_name AS member_name,
    m.email,
    b.title AS book_title,
    lo.loan_date,
    lo.due_date,
    lo.status
FROM loan lo
JOIN members m ON lo.member_id = m.member_id
JOIN book b ON lo.book_id = b.book_id
WHERE lo.status IN ('Issued', 'Overdue');

--3. Overdue Loans with Member Details 
--Retrieve all overdue loans showing member name, phone number, book title, library name, days overdue (calculated as difference between current date and due date), and 
--any fines paid for that loan.  
SELECT 
    m.full_name AS member_name,
    m.phone_number,
    b.title AS book_title,
    l.name AS library_name,
    DATEDIFF(DAY, lo.due_date, GETDATE()) AS days_overdue,
    ISNULL(SUM(fp.amount), 0) AS fine_paid
FROM loan lo
JOIN members m ON lo.member_id = m.member_id
JOIN book b ON lo.book_id = b.book_id
JOIN library l ON b.library_id = l.library_id
LEFT JOIN fine_payment fp ON lo.loan_id = fp.loan_id
WHERE lo.status = 'Overdue'
GROUP BY 
    m.full_name, m.phone_number, b.title, l.name, lo.due_date;

--4. Staff Performance Overview 
--For each library, show the library name, staff member names, their positions, and count of books managed at that library.  
SELECT 
    l.name AS library_name,
    s.full_name AS staff_name,
    s.position,
    COUNT(b.book_id) AS books_managed
FROM staff s
JOIN library l ON s.library_id = l.library_id
LEFT JOIN book b ON l.library_id = b.library_id
GROUP BY 
    l.name, s.full_name, s.position;

--5. Book Popularity Report 
--Display books that have been loaned at least 3 times. Include book title, ISBN, genre, total number of times loaned, and average review rating (if any reviews exist).  
SELECT 
    b.title,
    b.ISBN,
    b.genre,
    COUNT(lo.loan_id) AS times_loaned,
    AVG(r.rating) AS avg_rating
FROM book b
JOIN loan lo ON b.book_id = lo.book_id
LEFT JOIN review r ON b.book_id = r.book_id
GROUP BY 
    b.book_id, b.title, b.ISBN, b.genre
HAVING COUNT(lo.loan_id) >= 3;
--6. Member Reading History 
--Create a query that shows each member's complete borrowing history including: 
--member name, book titles borrowed (including currently borrowed and previously returned), loan dates, return dates, and any reviews they left for those books.  

SELECT 
    m.full_name AS member_name,
    b.title AS book_title,
    lo.loan_date,
    lo.return_date,
    r.rating,
    r.comments
FROM members m
JOIN loan lo ON m.member_id = lo.member_id
JOIN book b ON lo.book_id = b.book_id
LEFT JOIN review r 
    ON r.book_id = b.book_id 
    AND r.member_id = m.member_id
ORDER BY 
    m.full_name, lo.loan_date;
--7. Revenue Analysis by Genre 
--Calculate total fine payments collected for each book genre. Show genre name, total number of loans for that genre, total fine amount collected, and average fine per loan. 
SELECT 
    b.genre,
    COUNT(lo.loan_id) AS total_loans,
    SUM(fp.amount) AS total_fines_collected,
    AVG(fp.amount) AS average_fine_per_loan
FROM book b
JOIN loan lo ON b.book_id = lo.book_id
LEFT JOIN fine_payment fp ON lo.loan_id = fp.loan_id
GROUP BY b.genre;

--Write queries using aggregate functions and GROUP BY: 
--8. Monthly Loan Statistics 
--Generate a report showing the number of loans issued per month for the current year. 
--Include month name, total loans, total returned, and total still issued/overdue.  
SELECT 
    DATENAME(MONTH, loan_date) AS MonthName,
    COUNT(*) AS TotalLoans,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS TotalReturned,
    SUM(CASE WHEN status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS TotalActive
FROM loan
WHERE YEAR(loan_date) = YEAR(GETDATE())
GROUP BY DATENAME(MONTH, loan_date), MONTH(loan_date)
ORDER BY MONTH(loan_date);

--9. Member Engagement Metrics 
--For each member, calculate: total books borrowed, total books currently on loan, total 
--fines paid, and average rating they give in reviews. Only include members who have borrowed at least one book.  
SELECT 
    m.member_id,
    m.full_name,
    COUNT(l.loan_id) AS TotalBooksBorrowed,
    SUM(CASE WHEN l.status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS TotalBooksOnLoan,
    ISNULL(SUM(fp.amount),0) AS TotalFinesPaid,
    ISNULL(AVG(r.rating),0) AS AvgRatingGiven
FROM members m
JOIN loan l ON m.member_id = l.member_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
LEFT JOIN review r ON m.member_id = r.member_id
GROUP BY m.member_id, m.full_name
HAVING COUNT(l.loan_id) > 0
ORDER BY m.member_id;

--10. Library Performance Comparison 
--Compare libraries by showing: library name, total books owned, total active members (members with at least one loan), total revenue from fines, and average books per member.  
SELECT 
    lib.name AS LibraryName,
    COUNT(b.book_id) AS TotalBooksOwned,
    COUNT(DISTINCT l.member_id) AS TotalActiveMembers,
    ISNULL(SUM(fp.amount),0) AS TotalRevenueFromFines,
    CASE 
        WHEN COUNT(DISTINCT l.member_id) = 0 THEN 0
        ELSE CAST(COUNT(b.book_id) AS FLOAT)/COUNT(DISTINCT l.member_id)
    END AS AvgBooksPerMember
FROM library lib
LEFT JOIN book b ON lib.library_id = b.library_id
LEFT JOIN loan l ON b.book_id = l.book_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
GROUP BY lib.name;

--11. High-Value Books Analysis 
--Identify books priced above the average book price in their genre. Show book title, genre, price, genre average price, and difference from average.  
WITH GenreAvg AS (
    SELECT 
        genre,
        AVG(price) AS AvgPrice
    FROM book
    GROUP BY genre
)
SELECT 
    b.title,
    b.genre,
    b.price,
    g.AvgPrice AS GenreAvgPrice,
    b.price - g.AvgPrice AS DifferenceFromAvg
FROM book b
JOIN GenreAvg g ON b.genre = g.genre
WHERE b.price > g.AvgPrice
ORDER BY b.genre, DifferenceFromAvg DESC;
--12. Payment Pattern Analysis 
--Group payments by payment method and show: payment method, number of transactions, total amount collected, average payment amount, and percentage of total revenue.  
-- ???? ?????? ????????? ?????
DECLARE @TotalRevenue DECIMAL(10,2);
SELECT @TotalRevenue = SUM(amount) FROM fine_payment;

-- ????? ????????? ??? ????? ?????
SELECT 
    fp.payment_method,
    COUNT(*) AS NumberOfTransactions,
    SUM(fp.amount) AS TotalCollected,
    AVG(fp.amount) AS AvgPayment,
    CAST(SUM(fp.amount) * 100.0 / @TotalRevenue AS DECIMAL(5,2)) AS PercentOfTotalRevenue
FROM fine_payment fp
GROUP BY fp.payment_method
ORDER BY PercentOfTotalRevenue DESC;
--Create the following views: 
--13. vw_CurrentLoans 
--A view that shows all currently active loans (status 'Issued' or 'Overdue') with member details, book details, loan information, and calculated days until due (or days overdue).  
CREATE VIEW vw_CurrentLoans AS
SELECT 
    l.loan_id,
    m.member_id,
    m.full_name AS MemberName,
    m.email,
    m.phone_number,
    b.book_id,
    b.title AS BookTitle,
    b.genre,
    b.shelf_location,
    l.loan_date,
    l.due_date,
    l.status,
    CASE 
        WHEN l.due_date >= GETDATE() THEN DATEDIFF(DAY, GETDATE(), l.due_date)
        ELSE -DATEDIFF(DAY, l.due_date, GETDATE())  -- ???? ??????
    END AS DaysUntilDueOrOverdue
FROM loan l
JOIN members m ON l.member_id = m.member_id
JOIN book b ON l.book_id = b.book_id
WHERE l.status IN ('Issued','Overdue');
--14. vw_LibraryStatistics 
--A comprehensive view showing library-level statistics including total books, available books, total members, active loans, total staff, and total revenue from fines.  
CREATE VIEW vw_LibraryStatistics AS
SELECT 
    lib.library_id,
    lib.name AS LibraryName,
    COUNT(DISTINCT b.book_id) AS TotalBooks,
    SUM(CASE WHEN b.availability_status = 1 THEN 1 ELSE 0 END) AS AvailableBooks,
    COUNT(DISTINCT m.member_id) AS TotalMembers,
    SUM(CASE WHEN l.status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS ActiveLoans,
    COUNT(DISTINCT s.staff_id) AS TotalStaff,
    ISNULL(SUM(fp.amount),0) AS TotalRevenueFromFines
FROM library lib
LEFT JOIN book b ON lib.library_id = b.library_id
LEFT JOIN loan l ON b.book_id = l.book_id
LEFT JOIN members m ON l.member_id = m.member_id
LEFT JOIN staff s ON lib.library_id = s.library_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
GROUP BY lib.library_id, lib.name;




