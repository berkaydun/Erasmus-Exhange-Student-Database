-- 1) Prevent Home Country Application
CREATE OR REPLACE FUNCTION check_home_department_application()
RETURNS TRIGGER AS $$
DECLARE
    student_home_country VARCHAR(20);
    target_dept_country VARCHAR(20);
BEGIN
    -- Step 1: Retrieve the home country of the applicant
    -- Join EXCHANGE_STUDENT with DEPARTMENT to find the origin country
    SELECT D.Country INTO student_home_country 
    FROM EXCHANGE_STUDENT S
    JOIN DEPARTMENT D ON S.Dep_id = D.Dep_id
    WHERE S.S_no = NEW.S_no;

    -- Step 2: Retrieve the country of the target department
    SELECT Country INTO target_dept_country
    FROM DEPARTMENT
    WHERE Dep_id = NEW.Dep_id;

    -- Step 3: Validate the mobility rule
    -- If countries match, raise an exception and abort the transaction
    IF student_home_country = target_dept_country THEN
        RAISE EXCEPTION 'Violation of Mobility Rule: Student cannot apply to a department in their home country (%).', student_home_country;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Trigger Definition */
DROP TRIGGER IF EXISTS trg_prevent_home_application ON E_CANDIDATE;

CREATE TRIGGER trg_prevent_home_application
BEFORE INSERT ON E_CANDIDATE
FOR EACH ROW
EXECUTE FUNCTION check_home_department_application();

-- 2)Dynamic ECTS Calculation

CREATE OR REPLACE FUNCTION auto_update_curriculum_ects()
RETURNS TRIGGER AS $$
BEGIN
    -- Case 1: Handle INSERT or UPDATE actions
    -- Recalculate total ECTS for the referenced curriculum
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE CURRICULUM
        SET Total_ects = (SELECT COALESCE(SUM(ECTS), 0) FROM COURSE WHERE Curr_id = NEW.Curr_id)
        WHERE Curr_id = NEW.Curr_id;
    END IF;

    -- Case 2: Handle DELETE or UPDATE actions
    -- Recalculate total ECTS for the old curriculum (in case of a transfer)
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        UPDATE CURRICULUM
        SET Total_ects = (SELECT COALESCE(SUM(ECTS), 0) FROM COURSE WHERE Curr_id = OLD.Curr_id)
        WHERE Curr_id = OLD.Curr_id;
    END IF;

    RETURN NULL; -- Return NULL for AFTER triggers
END;
$$ LANGUAGE plpgsql;

/* Trigger Definition */
CREATE TRIGGER trg_maintain_curriculum_ects
AFTER INSERT OR UPDATE OR DELETE ON COURSE
FOR EACH ROW
EXECUTE FUNCTION auto_update_curriculum_ects();

-- 3) Component Weight Validation

CREATE OR REPLACE FUNCTION check_component_weight_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_total DECIMAL(5,2);
BEGIN
    -- Calculate the sum of weights for the specific Course, Assessment, and Type
    -- Note: This is an AFTER trigger, so the new row is already included in the sum
    SELECT COALESCE(SUM(Weight), 0) INTO current_total 
    FROM COMPONENT
    WHERE Course_id = NEW.Course_id
      AND Assessment_id = NEW.Assessment_id
      AND Type = NEW.Type;
      
    -- Check if the total exceeds 100
    IF current_total > 100 THEN
        RAISE EXCEPTION 'Total Weight for % components cannot exceed 100. Current total is %.', NEW.Type, current_total;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Trigger Definition */
CREATE TRIGGER trg_weight_limit
AFTER INSERT OR UPDATE ON COMPONENT
FOR EACH ROW
EXECUTE FUNCTION check_component_weight_limit();


-- 4) Equivalency Details Calculation

CREATE OR REPLACE FUNCTION calculate_equivalency_details()
RETURNS TRIGGER AS $$
DECLARE
    host_ects INT;
    host_lang VARCHAR;
    home_ects INT;
    home_lang VARCHAR;
BEGIN
    -- 1. Fetch details of the Host Course
    SELECT ECTS, Language INTO host_ects, host_lang
    FROM COURSE
    WHERE Course_id = NEW.Host_course_id;

    -- 2. Fetch details of the Home Course
    SELECT ECTS, Language INTO home_ects, home_lang
    FROM COURSE
    WHERE Course_id = NEW.Home_course_id;

    -- 3. Determine Language Match
    IF host_lang = home_lang THEN
        NEW.Language_match := TRUE;
    ELSE
        NEW.Language_match := FALSE;
    END IF;

    -- 4. Calculate Absolute ECTS Difference
    NEW.ECTS_diff := ABS(host_ects - home_ects);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Trigger Definition */
CREATE TRIGGER trg_set_equivalency_details
BEFORE INSERT OR UPDATE ON EQUIVALENCY
FOR EACH ROW
EXECUTE FUNCTION calculate_equivalency_details();

-- 5) Self-Reference Prevention

/* Function 1: Prevent Self-Equivalency */
CREATE OR REPLACE FUNCTION prevent_self_equivalency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Host_Course_id = NEW.Home_Course_id THEN
        RAISE EXCEPTION 'Data Integrity Error: A course cannot be equivalent to itself.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_no_self_equivalency
BEFORE INSERT OR UPDATE ON EQUIVALENCY
FOR EACH ROW
EXECUTE FUNCTION prevent_self_equivalency();

/* Function 2: Prevent Self-Prerequisite */
CREATE OR REPLACE FUNCTION check_self_prerequisite_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Course_id = NEW.Prerequisite_id THEN
        RAISE EXCEPTION 'Data Integrity Error: A course (%s) cannot be its own prerequisite.', NEW.Course_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_self_prerequisite
BEFORE INSERT OR UPDATE ON PREREQUISITE
FOR EACH ROW
EXECUTE FUNCTION check_self_prerequisite_func();

