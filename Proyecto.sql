CREATE DATABASE Proyecto;
USE Proyecto;

CREATE TABLE Consentimientos (

id_consentimiento INT PRIMARY KEY IDENTITY(1,1),
fecha_nacimiento DATE NOT NULL, 
  es_menor_edad AS 
        CASE 
            WHEN DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) < 18 THEN 1 
            ELSE 0 
        END,   -- Se calcula la edad  segun la fecha actual, // Campo calculado (0 = mayor, 1 = menor) 
consentimiento_adulto BIT NULL, -- 1 = Sí, 0 = No (solo si es menor)
nombre_adulto VARCHAR(100) NULL,  -- nombre del adulto responsable del menor           
documento_adulto VARCHAR(50) NULL, -- documento del adulto responsable del menor
aceptacion_terminos BIT NOT NULL,  -- aceptar terminos si es menor de edad         
fecha_aceptacion DATETIME DEFAULT GETDATE(), -- registra fecha de la  aceptación  
copia_autorizacion VARBINARY(MAX) NULL, -- Archivo digital (PDF, imagen, etc.)
validado_admin BIT DEFAULT 0  -- 1 = Validado, 0 = Pendiente


); 

CREATE TABLE Terminos_Condiciones (

 id_Terminos INT PRIMARY KEY IDENTITY(1,1),
 Version NVARCHAR(10) NOT NULL,   -- Ejemplo: v1.0, v2.1
 textoTerminos NVARCHAR(MAX) NOT NULL,  -- Texto legal completo ( datos sencibles, y contexto del proyecto FACEID
 fechaPublicacion DATE DEFAULT GETDATE()  -- Guarda fecha actual de los terminos realizados

);

CREATE TABLE Aceptacion_Terminos (
id_Aceptacion INT PRIMARY KEY IDENTITY(1,1),
id_consentimiento INT NOT NULL,   -- lo de menor de edad
id_Terminos INT NOT NULL, 
aceptado BIT NOT NULL,   -- El Bit ( representa boleanoo, -- 1 = Aceptó, 0 = Rechazó ) 
fechaAceptacion DATETIME DEFAULT GETDATE(), 

CONSTRAINT FK_Aceptacion_Consentimiento FOREIGN KEY (id_consentimiento)
REFERENCES Consentimientos(id_consentimiento), -- nombre de la FK, FK_Aceptacion_Consentimiento

CONSTRAINT FK_Aceptacion_Terminos FOREIGN KEY (id_Terminos)
 REFERENCES Terminos_Condiciones(id_Terminos)

 ); 

 CREATE TABLE Credenciales (
 id_credencial INT PRIMARY KEY IDENTITY(1,1),
 correo NVARCHAR(255) NOT NULL UNIQUE CHECK (correo LIKE '%@%.%'), -- formato correo, y unico
 contrasenaHash VARBINARY(256) NOT NULL, -- Contraseña encriptada/hasheada 
 fechaCreacion DATETIME DEFAULT GETDATE(), -- fecha en la que se registra las credenciales 
 ultimaModificacion DATETIME NULL,  -- modificaciones del uduario 
 estado NVARCHAR(20) DEFAULT 'Activo' -- Activo, Bloqueado, Inactivo

); 
--- la politica de los Caracteres de la contraseña 
CREATE TABLE  Politicas_Contrasenas (
id_politica INT PRIMARY KEY IDENTITY,
minLongitud INT NOT NULL CHECK (minLongitud >= 8),  -- minimo de caracteres 
maxLongitud INT NOT NULL CHECK (maxLongitud <= 15), -- maximo de caracteres
requiereMayusculas BIT DEFAULT 0, -- no es nesesario la mayuscula
requiereNumeros BIT DEFAULT 1, -- debe tener por lo menos  1 numero
requiereSimbolos BIT DEFAULT 0, -- no es necesario agragarle algun caracter

); 

--  tabla creada para que veas los intentos de fallos que se tiene al momento de ingresar la contraseña

CREATE TABLE Configuracion_seguridad ( 
id_configuracion INT PRIMARY KEY IDENTITY,
nombreConfiguracion NVARCHAR(100) NOT NULL, -- nombre de los intentos fallidos de una contraseña o correo // "IntentosFallidos", "TiempoBloqueoCuenta", "ReintentosCaptcha" 
valorConfiguracion NVARCHAR(100) NOT NULL,  -- cantidad de intentos fallidos  "3"
descripcion NVARCHAR(255) NULL -- Descripcion de lo que pasa por los intentos fallidos // " Número máximo de intentos de inicio de sesión fallidos antes de bloquear la cuenta"

); 

CREATE TABLE Sesion_usuario ( 
id_sesion INT PRIMARY KEY IDENTITY, 
id_credencial INT NOT NULL, -- credenciales ( correo y contraseña )
fechaInicio DATETIME DEFAULT GETDATE(), -- se guarda  la hora exacta el cual inicia sesion ( lo hace automaticamente ) 
fechaFin DATETIME NULL,  -- se guarda la fecha en la que finalizo la sesio  ( es NULL mientras la sesion esta activa por que no a terminado de registrase el usuario) 
IP_Origen NVARCHAR(50), -- Guarda la direccion IP donde el usuario inicia sesion
estadoSesion NVARCHAR(50) DEFAULT 'Activo', -- DEFAULT 'Activo', cuando la sesion esta en uso se guarda  automaticamente que esta activo ( sino, inactivo (cerro sesion manuelmente)) 
CONSTRAINT FK_SesionUsuario_Credencial FOREIGN KEY(id_credencial) 
REFERENCES Credenciales (id_credencial) -- FK SE LLAMA  FK_SesionUsuario_Credencial

); 

-- muestra la acciones que tiene la persona en el inicion de  sesion ( es como un registro de lo que se hace y se guarda ) 
CREATE TABLE Auditoria ( 
id_auditoria INT PRIMARY KEY IDENTITY, 
id_credencial INT,  
accion NVARCHAR (255),  -- se guarda la accion que hace el usuario 
fecha DATETIME DEFAULT GETDATE(), -- fecja y hora el la que hace el evento
descripcion  NVARCHAR(500), -- descrive la accion que hizo el usuario, por ejemplo El usuario intentó iniciar sesión con una contraseña incorrecta."
IP_Origen NVARCHAR(50), -- se muestra la IP donde se hizo la acccion 

CONSTRAINT FK_Auditoria_Credenciales   FOREIGN KEY ( id_credencial) REFERENCES Credenciales (id_credencial)
);

-- identifica solo los errores que tiene el usuario al inicar sesion 

CREATE TABLE  Log_Errores (
errorID INT PRIMARY KEY IDENTITY,
fecha DATETIME DEFAULT GETDATE(), -- muestra  la fecha en el que ocurre un error
id_credencial INT NULL , -- Guarda qué usuario estaba activo en el momento del error
tipoError NVARCHAR(100), -- indica el error que se genero // "Contraseña incorrecta", "Usuario no encontrado"
descripcion NVARCHAR(500),  -- tiene mas delles de la cuada del error
CONSTRAINT FK_Log_Credenciales   FOREIGN KEY ( id_credencial) REFERENCES Credenciales (id_credencial)

); 

CREATE TABLE Recuperacion_Contrasena (
    id_recuperacion INT PRIMARY KEY IDENTITY(1,1),
    id_credencial INT NOT NULL,                -- Usuario que solicita la recuperación
    token NVARCHAR(100) NOT NULL UNIQUE,       -- Token temporal único
    fechaSolicitud DATETIME DEFAULT GETDATE(), -- Cuándo se generó el token
    fechaExpiracion DATETIME NOT NULL,         -- Expira en 10–15 minutos
    usado BIT DEFAULT 0,                       -- 0 = no usado, 1 = ya usado
    intentosFallidos INT DEFAULT 0,            -- número de intentos de verificación fallidos
    estado NVARCHAR(20) DEFAULT 'Pendiente',   -- Pendiente, Verificado, Expirado, Bloqueado
    CONSTRAINT FK_Recuperacion_Credenciales FOREIGN KEY (id_credencial)
        REFERENCES Credenciales(id_credencial)
);

CREATE TABLE Log_Recuperacion (
    id_log_rec INT PRIMARY KEY IDENTITY(1,1),
    id_recuperacion INT NOT NULL,              -- Relación con la solicitud de recuperación
    accion NVARCHAR(255) NOT NULL,             -- Ej: "Token enviado", "Token expirado", "Contraseña restablecida"
    fecha DATETIME DEFAULT GETDATE(),          -- Cuándo ocurrió el evento
    descripcion NVARCHAR(500) NULL,            -- Detalle del evento
    CONSTRAINT FK_Log_Recuperacion FOREIGN KEY (id_recuperacion)
        REFERENCES Recuperacion_Contrasena(id_recuperacion)
);

CREATE TABLE Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre_rol NVARCHAR(50) NOT NULL,
    descripcion NVARCHAR(200)
);

CREATE TABLE Usuario (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
   Apellido NVARCHAR  (100) NOT NULL, 
    correo NVARCHAR(100) UNIQUE NOT NULL,
    contrasena NVARCHAR(200) NOT NULL,
    numero_ficha NVARCHAR(20),
   fecha_Registro DATETIME DEFAULT GETDATE(),
  estadoCuenta VARCHAR(20) DEFAULT 'Activo', -- o 'Desactivado'
    id_rol INT NOT NULL,
    FOREIGN KEY (id_rol) REFERENCES Rol(id_rol)
    
   FOREIGN KEY (id_Credenciale) REFERENCES Credencciales (id_Credenciale) 
);

CREATE TABLE Maquina (
    id_maquina INT IDENTITY(1,1) PRIMARY KEY,
    nombre_maquina NVARCHAR(100) NOT NULL,
    ubicacion NVARCHAR(150),
    estado NVARCHAR(30) DEFAULT 'Activo',
    clave_autenticacion NVARCHAR(100) NOT NULL
);

CREATE TABLE TipoRegistro (
    id_tipo INT IDENTITY(1,1) PRIMARY KEY,
    descripcion_tipo NVARCHAR(50) NOT NULL
);

CREATE TABLE Registro (

    id_registro INT IDENTITY(1,1) PRIMARY KEY,
    fecha_ingreso DATE NOT NULL,
    hora_ingreso TIME NOT NULL,
    fecha_salida DATE NULL,
    hora_salida TIME NULL,
    fecha_recepcion DATETIME DEFAULT GETDATE(),
    estado_transmision NVARCHAR(50) DEFAULT 'Recibido',
    id_usuario INT NOT NULL,
    id_maquina INT NOT NULL,
    id_tipo INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
    FOREIGN KEY (id_maquina) REFERENCES Maquina(id_maquina)
    FOREIGN KEY (id_tipo) REFERENCES TipoRegistro(id_tipo)
    
);

CREATE TABLE Ficha (
    id_Ficha INT PRIMARY KEY,
    codigoFicha VARCHAR(10) NOT NULL,
    nombrePrograma VARCHAR(100) NOT NULL,
    jornada VARCHAR(20) NOT NULL
);

CREATE TABLE Instructor (
    id_Instructor INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    idUsuario INT NOT NULL,
    FOREIGN KEY (id_Usuario) REFERENCES Usuario(id_Usuario)
);

CREATE TABLE HorarioFicha (
    id_HorarioFicha INT PRIMARY KEY,
    id_Ficha INT NOT NULL,
    diaSemana VARCHAR(15) NOT NULL,
    horaEntrada TIME NOT NULL,
    horaSalida TIME NOT NULL,
    FOREIGN KEY (id_Ficha) REFERENCES Ficha(id_Ficha)
);

CREATE TABLE AsignacionInstructor (
    id_Asignacion INT PRIMARY KEY,
    id_Instructor INT NOT NULL,
    id_HorarioFicha INT NOT NULL,
    fechaAsignacion DATE NOT NULL,
    activo BIT DEFAULT 1,
    FOREIGN KEY (id_Instructor) REFERENCES Instructor(id_Instructor),
    FOREIGN KEY (id_HorarioFicha) REFERENCES HorarioFicha(id_HorarioFicha),
    CONSTRAINT UQ_Asignacion UNIQUE (id_Instructor, id_HorarioFicha)
);

CREATE TABLE EstadoAsistencia (
    id_Estado INT PRIMARY KEY IDENTITY(1,1),
    nombreEstado VARCHAR(30) NOT NULL, -- Ej: Asistió, No Asistió, Llegó Tarde, Salida Anticipada
    descripcion VARCHAR(150)
);

CREATE TABLE RegistroAsistencia (
    id_Registro INT PRIMARY KEY,
    id_Usuario INT NOT NULL,
    fecha DATE NOT NULL,
    horaEntrada TIME NOT NULL,
    idHorarioFicha INT NOT NULL,
    minutosRetraso INT DEFAULT 0,
    FOREIGN KEY (id_Usuario) REFERENCES Usuario(id_Usuario),
    FOREIGN KEY (id_HorarioFicha) REFERENCES HorarioFicha(id_HorarioFicha)
   FOREIGN KEY (id_Estado) REFERENCES EstadoAsistencia(id_Estado);
   
);

CREATE TABLE EstadisticaUsuario (
    id_Estadistica INT PRIMARY KEY,
    id_Usuario INT NOT NULL,
    totalEntradas INT DEFAULT 0,
    totalRetrasos INT DEFAULT 0,
   totalInasistencias INT DEFAULT 0,
    porcentajePuntualidad DECIMAL(5,2),
   fechaActualizacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (id_Usuario) REFERENCES Usuario(id_Usuario)
);

CREATE TABLE Notificacion (
    id_Notificacion INT PRIMARY KEY IDENTITY(1,1),
    id_Usuario INT NOT NULL,
    tipoEvento VARCHAR(100) NOT NULL,  -- Ej: Retraso, Falta, Excusa, Cambio de Horario
    mensaje VARCHAR(255) NOT NULL,
    fechaEnvio DATETIME DEFAULT GETDATE(),
    estado VARCHAR(20) DEFAULT 'No Leída',  -- 'Leída' o 'No Leída'
    FOREIGN KEY (id_Usuario) REFERENCES Usuario(id_Usuario)
);
CREATE TABLE PerfilUsuario (
    idPerfil INT PRIMARY KEY IDENTITY(1,1),
    idUsuario INT NOT NULL,
    fotoPerfil VARBINARY(MAX) NULL,  -- Imagen en bytes o enlace al archivo
    tipoRegistro VARCHAR(20) CHECK (tipoRegistro IN ('Rostro', 'Huella', 'Clave')),
    confidencialidad VARCHAR(20) DEFAULT 'Privado', -- Etiquetado según A.5.13
    fechaCreacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario)
);
CREATE TABLE LogPerfil (
    idLog INT PRIMARY KEY IDENTITY(1,1),
    idUsuario INT NOT NULL,
    accion VARCHAR(50) NOT NULL,     -- 'Visualización', 'Edición', 'Eliminación'
    fechaAccion DATETIME DEFAULT GETDATE(),
    descripcion VARCHAR(255),
    FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario)
);

CREATE TABLE GestionHorario (
    idGestion INT PRIMARY KEY IDENTITY(1,1),
    idHorarioFicha INT NOT NULL,
    accion VARCHAR(20) CHECK (accion IN ('Crear','Modificar','Eliminar')),
    idUsuario INT NOT NULL, -- quién realizó la acción
    fechaAccion DATETIME DEFAULT GETDATE(),
    descripcion VARCHAR(255),
    FOREIGN KEY (idHorarioFicha) REFERENCES HorarioFicha(idHorarioFicha),
    FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario)
);

CREATE TABLE ConfiguracionUsuario (
    idConfiguracion INT PRIMARY KEY IDENTITY(1,1),
    idUsuario INT NOT NULL,
    permitirCambioCuenta BIT DEFAULT 1,
    permitirEliminacionCuenta BIT DEFAULT 1,
    fechaUltimaModificacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario)
);