ALTER SESSION SET "_ORACLE_SCRIPT" = true;

SET SERVEROUTPUT ON



---------------------------------------------------------------
-- 1)   GESTIÓN DE USUARIOS Y ROLES ---------------------------
---------------------------------------------------------------
-- CREAR ROLE "ROL_GESTOR" 
CREATE ROLE ROL_GESTOR;
GRANT  
ALTER ,
SELECT, 
UPDATE,
INSERT ON ILERNA_PAC.ASIGNATURAS_PAC TO ROL_GESTOR;
GRANT CREATE SESSION TO ROL_GESTOR;
-- CREAR USUARIO "GESTOR" 
CREATE USER GESTOR IDENTIFIED BY g1234;
-- ASIGNAR ROL A USUARIO
GRANT ROL_GESTOR TO GESTOR;
-- CONECTAR CON EL NUEVO USARIO
--CONN GESTOR / g1234; Elimino este comando porque a mi no me deja si no imprimir por pantalla--
SHOW USER;
-- REALIZAR LAS MODIFICACIONES DEL EJERCICIO
ALTER TABLE ILERNA_PAC.ASIGNATURAS_PAC DROP COLUMN CREDITOS;
ALTER TABLE ILERNA_PAC.ASIGNATURAS_PAC ADD CICLO VARCHAR(3);
INSERT INTO ILERNA_PAC.ASIGNATURAS_PAC VALUES (
    'DAX_M02B',
    'MP2.Bases de datos B',
    'Emilio Saurina Llabres',
    'DAX'
);
UPDATE ILERNA_PAC.ASIGNATURAS_PAC SET CICLO='DAM';
-- CONECTAR DE NUEVO CON EL USUARIO ILERNA_PAC
--CONN ILERNA_PAC / i1234;Elimino este comando porque a mi no me deja si no imprimir por pantalla--
SHOW USER

---------------------------------------------------------------
-- 2)	PROCEDIMIENTOS ---------------------------------------- 
---------------------------------------------------------------
-- ELIMINAR PROCEDIMIENTO ANTES DE CREARLO POR SI YA ESTA CREADO
DROP PROCEDURE RANKING_JUGADOR;
-- CREAR PROCEDIMIENTO "RANKING_JUGADOR"
CREATE OR REPLACE PROCEDURE RANKING_JUGADOR
(idjugador IN  NUMBER, puntos_add IN NUMBER,nombre_jugador OUT VARCHAR2,
apellidos_jugador OUT VARCHAR2, total_puntos OUT NUMBER,ranking OUT VARCHAR2
)AS

v_puntos NUMBER;

BEGIN

SELECT 
nombre INTO nombre_jugador
FROM
ilerna_pac.jugadores_pac
WHERE
id_jugador=idjugador;

SELECT apellidos INTO apellidos_jugador
FROM
ilerna_pac.jugadores_pac
WHERE
id_jugador=idjugador;

 SELECT puntos INTO v_puntos
FROM
ilerna_pac.jugadores_pac
WHERE
id_jugador=idjugador;

total_puntos:=v_puntos+puntos_add;

IF total_puntos<1001 THEN ranking:='Bronze';
ELSIF total_puntos<2001 THEN ranking:='Plata';
ELSIF total_puntos<3001 THEN ranking:='Oro';
ELSIF total_puntos<4001 THEN ranking:='Platino';
ELSE ranking:='Diamante';
END IF;                                                   
END;
/



---------------------------------------------------------------
-- 3)	FUNCIONES --------------------------------------------- 
---------------------------------------------------------------
-- ELIMINAR FUNCION ANTES DE CREARLA POR SI YA ESTA CREADA
DROP FUNCTION JUGADORES_POR_RANKING;
-- CREAR FUNCION "JUGADORES_POR_RANKING"
CREATE OR REPLACE FUNCTION JUGADORES_POR_RANKING
(ranking VARCHAR2)
RETURN NUMBER IS 
p_min NUMBER;
p_max NUMBER;
numero NUMBER;

BEGIN
SELECT PUNTOS_MIN INTO p_min FROM ILERNA_PAC.RANKING_PAC WHERE NOMBRE_RANKING=ranking;
SELECT PUNTOS_MAX INTO p_max FROM ILERNA_PAC.RANKING_PAC WHERE NOMBRE_RANKING=ranking;
SELECT COUNT(ID_JUGADOR)INTO numero FROM ILERNA_PAC.JUGADORES_PAC WHERE PUNTOS BETWEEN p_min AND p_max;

RETURN numero;
END;


/
---------------------------------------------------------------
-- 4)	TRIGGERS ---------------------------------------------- 
---------------------------------------------------------------
-- ELIMINAR TRIGGER ANTES DE CREARLo POR SI YA ESTA CREADo
DROP TRIGGER ACTUALIZA_RANKING_JUGADOR;
-- CREAR TRIGGER "ACTUALIZA_RANKING_JUGADOR"
CREATE OR REPLACE TRIGGER ACTUALIZA_RANKING_JUGADOR
  AFTER INSERT OR UPDATE 
  ON ilerna_pac.jugadores_pac
  FOR EACH ROW
DECLARE
fecha DATE;
total_puntos NUMBER;
ranking  VARCHAR2(80);

BEGIN
fecha:=sysdate;
total_puntos:=:new.puntos;
IF total_puntos<1001 THEN ranking:='Bronze';
ELSIF total_puntos<2001 THEN ranking:='Plata';
ELSIF total_puntos<3001 THEN ranking:='Oro';
ELSIF total_puntos<4001 THEN ranking:='Platino';
ELSE ranking:='Diamante';
END IF;                                      

 dbms_output.put_line(
                           'A fecha de '
                             || fecha
                             || '. El jugador '
                             || :new.nombre
                              || ' '
                             || :new.apellidos
                             || ' est� en el nivel '
                             || ranking
                             || ' con un total de '
                             || :new.puntos
                             || ' puntos'
                            
                             );
END;

/
---------------------------------------------------------------
-- 5)   BLOQUES ANÓNIMOS PARA PRUEBAS ------------------------- 
---------------------------------------------------------------
SHOW USER;

-- COMPROBACIÓN GESTIÓN USUARIOS Y ROLES
EXECUTE dbms_output.put_line('-- COMPROBACION GESTION USUARIOS Y ROLES --');
/
DECLARE
asignatura VARCHAR2(80);
profesor VARCHAR2(80);

BEGIN   
SELECT nombre_asignatura,nombre_profesor INTO asignatura,profesor FROM ilerna_pac.asignaturas_pac 
WHERE id_asignatura='DAX_M02B';
dbms_output.put_line(
                             
                             'El profesor de '
                             || asignatura
                             || ' se llama '
                             || profesor
                                              );
EXCEPTION
WHEN no_data_found THEN dbms_output.put_line('No existe el id de la asignatura');
END;

/
-- COMPROBACIÓN DE TRIGGER ACTUALIZA_RANKING_JUGADOR
EXECUTE dbms_output.put_line('-- COMPROBACION DE TRIGGER ACTUALIZA_RANKING_JUGADOR --');
/
DECLARE
vpuntos number :=&puntos;
PUNTUACION EXCEPTION;
v_jugador NUMBER;
v2_jugador NUMBER;

BEGIN

INSERT INTO ilerna_pac.jugadores_pac VALUES (11,'Angel','Mercadal Lopez',0 );
v_jugador:=11;
SELECT id_jugador INTO v2_jugador FROM ilerna_pac.jugadores_pac WHERE id_jugador=v_jugador; 
IF vpuntos NOT BETWEEN 0 AND 9999 THEN RAISE PUNTUACION;
ELSIF v2_jugador=NULL THEN RAISE NO_DATA_FOUND;
END IF;

UPDATE ilerna_pac.jugadores_pac SET puntos=vpuntos WHERE id_jugador=11;
EXCEPTION
WHEN PUNTUACION THEN DBMS_OUTPUT.PUT_LINE('La puntuaci�n debe estar entre 0 y 9999');
WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('El jugador no existe en la base de datos');
END;
/
-- COMPROBACIÓN DEL PROCEDIMIENTO RANKING_JUGADOR
EXECUTE dbms_output.put_line('-- COMPROBACION DEL PROCEDIMIENTO RANKING_JUGADOR --');
/
DECLARE
nombre_jugador VARCHAR2(80);
apellidos_jugador VARCHAR2(80);
total_puntos NUMBER;
ranking  VARCHAR2(80);
idjugador number :=&id_jugador;
add_puntos NUMBER :=&puntos_extra;
BEGIN   
RANKING_JUGADOR(idjugador,add_puntos,nombre_jugador ,
apellidos_jugador , total_puntos ,ranking);
dbms_output.put_line('El jugador '
                             || nombre_jugador
                             ||' '
                             || apellidos_jugador
                             || ' tendr� '
                             || total_puntos
                             || ' puntos'
                             || ' y pasa al nivel de ranking '
                             || ranking )  ;
EXCEPTION
WHEN no_data_found THEN dbms_output.put_line('No existe jugador con esta ID');
END;


/
-- COMPROBACIÓN DE LA FUNCION JUGADORES_POR_RANKING
EXECUTE dbms_output.put_line('-- COMPROBACION DE LA FUNCION JUGADORES_POR_RANKING --');

/
DECLARE

nombre_ranking VARCHAR2(80) :='&nombre_ranking';
total NUMBER;

BEGIN   
total:=JUGADORES_POR_RANKING(nombre_ranking);
dbms_output.put_line(
                             
                             'En el ranking '
                             || nombre_ranking
                             || ', tenemos a '
                             || total
                             || ' jugadores');
                           
EXCEPTION
WHEN no_data_found THEN dbms_output.put_line('No existe nombre de ranking con este nombre');
END;



