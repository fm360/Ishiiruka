// Copyright 2008 Dolphin Emulator Project
// Licensed under GPLv2+
// Refer to the license.txt file included.

#pragma once

#include <map>
#include <memory>
#include <string>

#include "Common/CommonTypes.h"

// You're not meant to keep around SignatureDB objects persistently. Use 'em, throw them away.

class PPCSymbolDB;
class SignatureDBFormatHandler;

class SignatureDB
{
public:
	enum class HandlerType
	{
		DSY,
		CSV,
		MEGA
	};
	explicit SignatureDB(HandlerType handler);
	explicit SignatureDB(const std::string& file_path);

	static HandlerType GetHandlerType(const std::string& file_path);

	void Clear();
	// Does not clear. Remember to clear first if that's what you want.
	bool Load(const std::string& file_path);
	bool Save(const std::string& file_path) const;
	void List() const;

	void Populate(const PPCSymbolDB* func_db, const std::string& filter = "");
	void Apply(PPCSymbolDB* func_db) const;

	bool Add(u32 start_addr, u32 size, const std::string& name);

private:
	std::unique_ptr<SignatureDBFormatHandler> CreateFormatHandler(HandlerType handler) const;
	std::unique_ptr<SignatureDBFormatHandler> m_handler;
};

class SignatureDBFormatHandler
{
public:
	virtual ~SignatureDBFormatHandler();

	virtual void Clear() = 0;
	virtual bool Load(const std::string& file_path) = 0;
	virtual bool Save(const std::string& file_path) const = 0;
	virtual void List() const = 0;

	virtual void Populate(const PPCSymbolDB* func_db, const std::string& filter = "") = 0;
	virtual void Apply(PPCSymbolDB* func_db) const = 0;

	virtual bool Add(u32 startAddr, u32 size, const std::string& name) = 0;
};

class HashSignatureDB : public SignatureDBFormatHandler
{
public:
	struct DBFunc
	{
		u32 size;
		std::string name;
		std::string object_name;
		std::string object_location;
		DBFunc() : size(0) {}
	};
	using FuncDB = std::map<u32, DBFunc>;

	static u32 ComputeCodeChecksum(u32 offsetStart, u32 offsetEnd);

	virtual void Clear() override;
	virtual void List() const override;

	virtual void Populate(const PPCSymbolDB* func_db, const std::string& filter = "") override;
	virtual void Apply(PPCSymbolDB* func_db) const override;

	virtual bool Add(u32 startAddr, u32 size, const std::string& name) override;

protected:
	// Map from signature to function. We store the DB in this map because it optimizes the
	// most common operation - lookup. We don't care about ordering anyway.
	FuncDB m_database;
};
