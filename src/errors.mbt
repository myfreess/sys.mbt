///|
pub suberror SysError {
  Raw(Int)
  Simple(SysErrorKind)
  Message(String)
} derive(Show)

///|
pub enum SysErrorKind {
  /// An entity was not found, often a file.
  NotFound
  /// The operation lacked the necessary privileges to complete.
  PermissionDenied
  /// The connection was refused by the remote server.
  ConnectionRefused
  /// The connection was reset by the remote server.
  ConnectionReset
  /// The remote host is not reachable.
  HostUnreachable
  /// The network containing the remote host is not reachable.
  NetworkUnreachable
  /// The connection was aborted (terminated) by the remote server.
  ConnectionAborted
  /// The network operation failed because it was not connected yet.
  NotConnected
  /// A socket address could not be bound because the address is already in
  /// use elsewhere.
  AddrInUse
  /// A nonexistent interface was requested or the requested address was not
  /// local.
  AddrNotAvailable
  /// The system's networking is down.
  NetworkDown
  /// The operation failed because a pipe was closed.
  BrokenPipe
  /// An entity already exists, often a file.
  AlreadyExists
  /// The operation needs to block to complete, but the blocking operation was
  /// requested to not occur.
  WouldBlock
  /// A filesystem object is, unexpectedly, not a directory.
  ///
  /// For example, a filesystem path was specified where one of the intermediate directory
  /// components was, in fact, a plain file.
  NotADirectory
  /// The filesystem object is, unexpectedly, a directory.
  ///
  /// A directory was specified when a non-directory was expected.
  IsADirectory
  /// A non-empty directory was specified where an empty directory was expected.
  DirectoryNotEmpty
  /// The filesystem or storage medium is read-only, but a write operation was attempted.
  ReadOnlyFilesystem
  /// Loop in the filesystem or IO subsystem; often, too many levels of symbolic links.
  ///
  /// There was a loop (or excessively long chain) resolving a filesystem object
  /// or file IO object.
  ///
  /// On Unix this is usually the result of a symbolic link loop; or, of exceeding the
  /// system-specific limit on the depth of symlink traversal.
  FilesystemLoop
  /// Stale network file handle.
  ///
  /// With some network filesystems, notably NFS, an open file (or directory) can be invalidated
  /// by problems with the network or server.
  StaleNetworkFileHandle
  /// A parameter was incorrect.
  InvalidInput
  /// The I/O operation's timeout expired, causing it to be canceled.
  TimedOut
  /// The underlying storage (typically, a filesystem) is full.
  ///
  /// This does not include out of quota errors.
  StorageFull
  /// Seek on unseekable file.
  ///
  /// Seeking was attempted on an open file handle which is not suitable for seeking - for
  /// example, on Unix, a named pipe opened with `File::open`.
  NotSeekable
  /// Filesystem quota or some other kind of quota was exceeded.
  QuotaExceeded
  /// File larger than allowed or supported.
  ///
  /// This might arise from a hard limit of the underlying filesystem or file access API, or from
  /// an administratively imposed resource limitation.  Simple disk full, and out of quota, have
  /// their own errors.
  FileTooLarge
  /// Resource is busy.
  ResourceBusy
  /// Executable file is busy.
  ///
  /// An attempt was made to write to a file which is also in use as a running program.  (Not all
  /// operating systems detect this situation.)
  ExecutableFileBusy
  /// Deadlock (avoided).
  ///
  /// A file locking operation would result in deadlock.  This situation is typically detected, if
  /// at all, on a best-effort basis.
  Deadlock
  /// Cross-device or cross-filesystem (hard) link or rename.
  CrossesDevices
  /// Too many (hard) links to the same filesystem object.
  ///
  /// The filesystem does not support making so many hardlinks to the same file.
  TooManyLinks
  /// A filename was invalid.
  ///
  /// This error can also cause if it exceeded the filename length limit.
  InvalidFilename
  /// Program argument list too long.
  ///
  /// When trying to run an external program, a system or process limit on the size of the
  /// arguments would have been exceeded.
  ArgumentListTooLong
  /// This operation was interrupted.
  ///
  /// Interrupted operations can typically be retried.
  Interrupted
  /// This operation is unsupported on this platform.
  ///
  /// This means that the operation can never succeed.
  Unsupported
  /// An operation could not be completed, because it failed
  /// to allocate enough memory.
  OutOfMemory
  /// The operation was partially successful and needs to be checked
  /// later on due to not blocking.
  InProgress
  /// Any I/O error from the standard library that's not part of this list.
  ///
  /// Errors that are `Uncategorized` now may move to a different or a new
  /// [`ErrorKind`] variant in the future. It is not recommended to match
  /// an error against `Uncategorized`; use a wildcard match (`_`) instead.
  Uncategorized
} derive(Show, Eq)

///|
extern "c" fn moonbit_errno_get_errcode() -> Int = "moonbit_errno_get_errcode"

///|
fn last_sys_error() -> SysError {
  Raw(moonbit_errno_get_errcode())
}

///|
fn decode_sys_error_kind_win32(errno : Int) -> SysErrorKind {
  match errno {
    @win32.ERROR_ACCESS_DENIED => return PermissionDenied
    @win32.ERROR_ALREADY_EXISTS => return AlreadyExists
    @win32.ERROR_FILE_EXISTS => return AlreadyExists
    @win32.ERROR_BROKEN_PIPE => return BrokenPipe
    @win32.ERROR_FILE_NOT_FOUND
    | @win32.ERROR_PATH_NOT_FOUND
    | @win32.ERROR_INVALID_DRIVE
    | @win32.ERROR_BAD_NETPATH
    | @win32.ERROR_BAD_NET_NAME => return NotFound
    @win32.ERROR_NO_DATA => return BrokenPipe
    @win32.ERROR_INVALID_NAME | @win32.ERROR_BAD_PATHNAME =>
      return InvalidFilename
    @win32.ERROR_INVALID_PARAMETER => return InvalidInput
    @win32.ERROR_NOT_ENOUGH_MEMORY | @win32.ERROR_OUTOFMEMORY =>
      return OutOfMemory
    @win32.ERROR_SEM_TIMEOUT
    | @win32.ERROR_DRIVER_CANCEL_TIMEOUT
    | @win32.ERROR_OPERATION_ABORTED
    | @win32.ERROR_SERVICE_REQUEST_TIMEOUT
    | @win32.ERROR_COUNTER_TIMEOUT
    | @win32.ERROR_TIMEOUT
    | @win32.ERROR_RESOURCE_CALL_TIMED_OUT
    | @win32.ERROR_CTX_MODEM_RESPONSE_TIMEOUT
    | @win32.ERROR_CTX_CLIENT_QUERY_TIMEOUT
    | @win32.ERROR_DS_TIMELIMIT_EXCEEDED
    | @win32.DNS_ERROR_RECORD_TIMED_OUT
    | @win32.ERROR_IPSEC_IKE_TIMED_OUT
    | @win32.ERROR_RUNLEVEL_SWITCH_TIMEOUT
    // WAIT_TIMEOUT only used in multithreading applications
    // | @win32.WAIT_TIMEOUT
    //  File Replication Service, seems only windows server have it
    // | @win32.FRS_ERR_SYSVOL_POPULATE_TIMEOUT
    | @win32.ERROR_RUNLEVEL_SWITCH_AGENT_TIMEOUT => return TimedOut
    @win32.ERROR_CALL_NOT_IMPLEMENTED => return Unsupported
    @win32.ERROR_HOST_UNREACHABLE => return HostUnreachable
    @win32.ERROR_NETWORK_UNREACHABLE => return NetworkUnreachable
    @win32.ERROR_DIRECTORY => return NotADirectory
    @win32.ERROR_DIRECTORY_NOT_SUPPORTED => return IsADirectory
    @win32.ERROR_DIR_NOT_EMPTY => return DirectoryNotEmpty
    @win32.ERROR_WRITE_PROTECT => return ReadOnlyFilesystem
    @win32.ERROR_DISK_FULL | @win32.ERROR_HANDLE_DISK_FULL => return StorageFull
    @win32.ERROR_SEEK_ON_DEVICE => return NotSeekable
    @win32.ERROR_DISK_QUOTA_EXCEEDED => return QuotaExceeded
    @win32.ERROR_FILE_TOO_LARGE => return FileTooLarge
    @win32.ERROR_BUSY => return ResourceBusy
    @win32.ERROR_POSSIBLE_DEADLOCK => return Deadlock
    @win32.ERROR_NOT_SAME_DEVICE => return CrossesDevices
    @win32.ERROR_TOO_MANY_LINKS => return TooManyLinks
    @win32.ERROR_FILENAME_EXCED_RANGE => return InvalidFilename
    @win32.ERROR_CANT_RESOLVE_FILENAME => return FilesystemLoop
    _ => ()
  }
  match errno {
    @win32.WSAEACCES => PermissionDenied
    @win32.WSAEADDRINUSE => AddrInUse
    @win32.WSAEADDRNOTAVAIL => AddrNotAvailable
    @win32.WSAECONNABORTED => ConnectionAborted
    @win32.WSAECONNREFUSED => ConnectionRefused
    @win32.WSAECONNRESET => ConnectionReset
    @win32.WSAEINVAL => InvalidInput
    @win32.WSAENOTCONN => NotConnected
    @win32.WSAEWOULDBLOCK => WouldBlock
    @win32.WSAETIMEDOUT => TimedOut
    @win32.WSAEHOSTUNREACH => HostUnreachable
    @win32.WSAENETDOWN => NetworkDown
    @win32.WSAENETUNREACH => NetworkUnreachable
    @win32.WSAEDQUOT => QuotaExceeded
    _ => Uncategorized
  }
}

///|
fn decode_sys_error_kind_linux(errno : Int) -> SysErrorKind {
  match errno {
    @linux.E2BIG => ArgumentListTooLong
    @linux.EADDRINUSE => AddrInUse
    @linux.EADDRNOTAVAIL => AddrNotAvailable
    @linux.EBUSY => ResourceBusy
    @linux.ECONNABORTED => ConnectionAborted
    @linux.ECONNREFUSED => ConnectionRefused
    @linux.ECONNRESET => ConnectionReset
    @linux.EDEADLK => Deadlock
    @linux.EDQUOT => QuotaExceeded
    @linux.EEXIST => AlreadyExists
    @linux.EFBIG => FileTooLarge
    @linux.EHOSTUNREACH => HostUnreachable
    @linux.EINTR => Interrupted
    @linux.EINVAL => InvalidInput
    @linux.EISDIR => IsADirectory
    @linux.ELOOP => FilesystemLoop
    @linux.ENOENT => NotFound
    @linux.ENOMEM => OutOfMemory
    @linux.ENOSPC => StorageFull
    @linux.ENOSYS => Unsupported
    @linux.EMLINK => TooManyLinks
    @linux.ENAMETOOLONG => InvalidFilename
    @linux.ENETDOWN => NetworkDown
    @linux.ENETUNREACH => NetworkUnreachable
    @linux.ENOTCONN => NotConnected
    @linux.ENOTDIR => NotADirectory
    @linux.ENOTEMPTY => DirectoryNotEmpty
    @linux.EPIPE => BrokenPipe
    @linux.EROFS => ReadOnlyFilesystem
    @linux.ESPIPE => NotSeekable
    @linux.ESTALE => StaleNetworkFileHandle
    @linux.ETIMEDOUT => TimedOut
    @linux.ETXTBSY => ExecutableFileBusy
    @linux.EXDEV => CrossesDevices
    @linux.EINPROGRESS => InProgress
    @linux.EACCES | @linux.EPERM => PermissionDenied
    // These two constants can have the same value on some systems,
    // but different values on others, so we can't use a match
    // clause
    x if x == @linux.EAGAIN || x == @linux.EWOULDBLOCK => WouldBlock
    _ => Uncategorized
  }
}

///|
pub fn SysError::kind(self : SysError) -> SysErrorKind {
  match self {
    SysError::Raw(errno) =>
      if moonbit_os_iswin32() {
        decode_sys_error_kind_win32(errno)
      } else {
        decode_sys_error_kind_linux(errno)
      }
    SysError::Simple(kind) => kind
    SysError::Message(_) => Uncategorized
  }
}

///|
test {
  if moonbit_os_iswin32() {
    inspect(Raw(10022).kind(), content="InvalidInput")
  }
}
